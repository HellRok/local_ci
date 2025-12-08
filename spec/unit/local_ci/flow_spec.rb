require "spec_helper"

describe LocalCI::Flow do
  describe "#initialize" do
    context "when creating parallel" do
      it "call Rake::MultiTask" do
        task = double(:task, prerequisites: [])
        allow(task).to receive(:comment=)
        allow(Rake::Task).to receive(:[]).and_return(task)
        allow(Rake::Task).to receive(:define_task)
        expect(Rake::MultiTask).to receive(:define_task).with("ci:parallel:jobs")

        LocalCI::Flow.new(
          name: "parallel",
          heading: "heading",
          parallel: true,
          block: -> {}
        )
      end
    end

    context "when creating sequential" do
      it "call Rake::Task" do
        task = double(:task, prerequisites: [])
        allow(task).to receive(:comment=)
        allow(Rake::Task).to receive(:[]).and_return(task)
        allow(Rake::Task).to receive(:define_task)
        expect(Rake::Task).to receive(:define_task).with("ci:sequential:jobs")

        LocalCI::Flow.new(
          name: "sequential",
          heading: "heading",
          parallel: false,
          block: -> {}
        )
      end
    end

    it "creates the expected tasks" do
      LocalCI::Flow.new(
        name: "test",
        heading: "heading",
        parallel: true,
        block: -> {}
      )

      expect(Rake::Task.task_defined?("ci")).to be(true)
      expect(Rake::Task.task_defined?("ci:setup")).to be(true)
      expect(Rake::Task.task_defined?("ci:test")).to be(true)
      expect(Rake::Task.task_defined?("ci:test:setup")).to be(true)
      expect(Rake::Task.task_defined?("ci:test:jobs")).to be(true)
      expect(Rake::Task.task_defined?("ci:test:teardown")).to be(true)
      expect(Rake::Task.task_defined?("ci:teardown")).to be(true)
    end

    it "gives tasks the right comments" do
      LocalCI::Flow.new(
        name: "test",
        heading: "heading",
        parallel: true,
        block: -> {}
      )

      expect(Rake::Task["ci"].comment).to eq("Run the CI suite")
      expect(Rake::Task["ci:setup"].comment).to eq("Setup the system to run CI")
      expect(Rake::Task["ci:teardown"].comment).to eq("Cleanup after the CI")
      expect(Rake::Task["ci:test"].comment).to eq("heading")
    end

    it "has the correct prerequisites for all tasks" do
      LocalCI::Flow.new(
        name: "test",
        heading: "heading",
        parallel: true,
        block: -> {}
      )

      expect(Rake::Task["ci"].prerequisites).to eq(["ci:setup", "ci:test"])
      expect(Rake::Task["ci:test"].prerequisites).to eq(["ci:test:teardown"])
      expect(Rake::Task["ci:test:teardown"].prerequisites).to eq(["ci:test:jobs"])
      expect(Rake::Task["ci:test:jobs"].prerequisites).to eq(["ci:test:setup"])
      expect(Rake::Task["ci:test:setup"].prerequisites).to eq(["ci:setup"])
    end

    it "calls the expected jobs" do
      allow(LocalCI::Job).to receive(:new)

      job_1_block = -> {}

      flow = LocalCI::Flow.new(
        name: "test",
        heading: "heading",
        parallel: true,
        block: -> {
          job("Job 1", &job_1_block)
          job("Job 2", "ls", "-la")
        }
      )

      expect(LocalCI::Job).to have_received(:new).with(
        flow: flow,
        name: "Job 1",
        command: [],
        block: job_1_block
      )

      expect(LocalCI::Job).to have_received(:new).with(
        flow: flow,
        name: "Job 2",
        command: ["ls", "-la"],
        block: nil
      )
    end
  end

  describe "#after_jobs" do
    before do
      @flow = LocalCI::Flow.new(
        name: "flow",
        heading: "heading",
        parallel: true,
        block: -> {}
      )

      @ci = double(:ci, already_invoked: false)
      allow(LocalCI::Task).to receive(:[]).with("ci").and_return(@ci)

      @flow_teardown = double(:flow_teardown)
      allow(@flow_teardown).to receive(:invoke)
      allow(LocalCI::Task).to receive(:[]).with("ci:flow:teardown").and_return(@flow_teardown)

      @teardown = double(:teardown)
      allow(@teardown).to receive(:invoke)
      allow(LocalCI::Task).to receive(:[]).with("ci:teardown").and_return(@teardown)
    end

    context "when there are no failures" do
      it "runs ci:flow:teardown" do
        expect(@flow_teardown).to receive(:invoke)

        ::Rake::Task["ci:flow"].invoke
      end

      context "when run in isolation" do
        it "runs ci:teardown" do
          expect(@teardown).to receive(:invoke)

          ::Rake::Task["ci:flow"].invoke
        end
      end

      context "when not run in isolation" do
        before do
          allow(@ci).to receive(:already_invoked).and_return(true)
        end

        it "does not run ci:teardown" do
          expect(@teardown).not_to receive(:invoke)

          ::Rake::Task["ci:flow"].invoke
        end
      end
    end

    context "when there are failures" do
      before do
        @failure = double(:failure, display: "hi")
        @flow.failures << @failure

        allow(@flow).to receive(:abort)
      end

      it "runs ci:flow:teardown" do
        expect(@flow_teardown).to receive(:invoke)

        ::Rake::Task["ci:flow"].invoke
      end

      it "invokes ci:teardown" do
        expect(@teardown).to receive(:invoke)

        ::Rake::Task["ci:flow"].invoke
      end

      it "displays the failures" do
        expect(@failure).to receive(:display)

        ::Rake::Task["ci:flow"].invoke
      end

      it "aborts with a message" do
        expect(@flow).to receive(:abort).with(/heading failed, see CI\.log for more\./)

        ::Rake::Task["ci:flow"].invoke
      end
    end
  end
end
