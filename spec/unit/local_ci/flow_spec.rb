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
      expect(Rake::Task.task_defined?("ci:test:failure_check")).to be(true)
      expect(Rake::Task.task_defined?("ci:teardown")).to be(true)
      expect(Rake::Task.task_defined?("ci:failure_check")).to be(true)
    end

    it "gives tasks the right comments" do
      LocalCI::Flow.new(
        name: "test",
        heading: "heading",
        parallel: true,
        block: -> {}
      )

      expect(Rake::Task["ci"].comment).to eq("Run the CI suite")
      expect(Rake::Task["ci:test"].comment).to eq("heading")
    end

    it "has the correct prerequisites for all tasks" do
      LocalCI::Flow.new(
        name: "test",
        heading: "heading",
        parallel: true,
        block: -> {}
      )

      expect(Rake::Task["ci"].prerequisites).to eq(
        [
          "ci:setup",
          "ci:test:failure_check",
          "ci:teardown",
          "ci:failure_check"
        ]
      )
      expect(Rake::Task["ci:test"].prerequisites).to eq(["ci:test:failure_check"])
      expect(Rake::Task["ci:test:failure_check"].prerequisites).to eq(["ci:test:teardown"])
      expect(Rake::Task["ci:test:teardown"].prerequisites).to eq(["ci:test:jobs"])
      expect(Rake::Task["ci:test:jobs"].prerequisites).to eq(["ci:test:setup"])
      expect(Rake::Task["ci:test:setup"].prerequisites).to eq([])
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

  describe "ci:flow:failure_check" do
    before do
      @flow = LocalCI::Flow.new(
        name: "flow",
        heading: "heading",
        parallel: true,
        block: -> {}
      )
    end

    it "does nothing when there are no errors" do
      expect(@flow).not_to receive(:abort)

      ::Rake::Task["ci:flow:failure_check"].invoke
    end

    it "displays the failures and aborts when there are failures" do
      expect(@flow).to receive(:abort).with(/heading failed, see CI\.log for more\./)

      failure = double(:failure)
      expect(failure).to receive(:display)
      @flow.failures << failure

      ::Rake::Task["ci:flow:failure_check"].invoke
    end
  end
end
