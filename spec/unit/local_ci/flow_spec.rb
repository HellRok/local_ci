require "spec_helper"

describe LocalCI::Flow do
  describe "#initialize" do
    context "when creating parallel" do
      it "calls Rake::MultiTask" do
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
      it "calls Rake::Task" do
        task = double(:task, prerequisites: [])
        expect(task).to receive(:comment=).at_least(:once)
        expect(Rake::Task).to receive(:[]).and_return(task).at_least(:once)
        expect(Rake::Task).to receive(:define_task).with("ci:sequential:jobs").at_least(:once)
        expect(Rake::Task).to receive(:define_task).at_least(:once)

        LocalCI::Flow.new(
          name: "sequential",
          heading: "heading",
          parallel: false,
          block: -> {}
        )
      end
    end

    context "when actions is true" do
      it "creates the expected tasks" do
        LocalCI::Flow.new(
          name: "actions",
          heading: "heading",
          parallel: true,
          actions: true,
          block: -> {}
        )

        expect(Rake::Task.task_defined?("ci:actions")).to be(true)
        expect(Rake::Task.task_defined?("ci:actions:setup")).to be(true)
        expect(Rake::Task.task_defined?("ci:actions:jobs")).to be(true)
        expect(Rake::Task.task_defined?("ci:actions:teardown")).to be(true)
      end

      it "registers itself" do
        flow = LocalCI::Flow.new(
          name: "actions",
          heading: "heading",
          parallel: true,
          actions: true,
          block: -> {}
        )

        expect(LocalCI.flows).to eq([flow])
      end
    end

    context "when actions is false" do
      it "creates the expected tasks" do
        LocalCI::Flow.new(
          name: "actionless",
          heading: "heading",
          parallel: true,
          actions: false,
          block: -> {}
        )

        expect(Rake::Task.task_defined?("ci:actionless")).to be(true)
        expect(Rake::Task.task_defined?("ci:actionless:setup")).to be(false)
        expect(Rake::Task.task_defined?("ci:actionless:jobs")).to be(true)
        expect(Rake::Task.task_defined?("ci:actionless:teardown")).to be(false)
      end

      it "does not register itself" do
        LocalCI::Flow.new(
          name: "actionless",
          heading: "heading",
          parallel: true,
          actions: false,
          block: -> {}
        )

        expect(LocalCI.flows).to eq([])
      end
    end

    it "gives tasks the right comments" do
      LocalCI::Flow.new(
        name: "test",
        heading: "heading",
        parallel: true,
        block: -> {}
      )

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
        @failure = double(:failure, job: "job", message: "hi")
        @flow.failures << @failure

        allow(@flow).to receive(:abort)

        @output = double(:output)
        allow(@output).to receive(:failures)
        allow(@flow).to receive(:output).and_return(@output)
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
        expect(@output).to receive(:failures)

        ::Rake::Task["ci:flow"].invoke
      end

      it "aborts with a message" do
        expect(@flow).to receive(:abort).with(/heading failed, see ci\.log for more\./)

        ::Rake::Task["ci:flow"].invoke
      end
    end
  end
end
