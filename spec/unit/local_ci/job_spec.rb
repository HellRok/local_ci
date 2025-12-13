require "spec_helper"

describe LocalCI::Job do
  before do
    @output = double(:output)
    allow(@output).to receive(:update)

    @flow = LocalCI::Flow.new(
      name: "flow",
      heading: "heading",
      parallel: true,
      block: -> {}
    )
    allow(@flow).to receive(:output).and_return(@output)
  end

  describe "#initialize" do
    it "creates a new job with the right arguments" do
      job = LocalCI::Job.new(
        flow: @flow,
        name: "The Job Name!",
        command: "command",
        block: "block"
      )

      expect(job.flow).to eq(@flow)
      expect(job.name).to eq("The Job Name!")
      expect(job.command).to eq("command")
      expect(job.block).to eq("block")
      expect(job.task).to eq("ci:flow:jobs:the_job_name")
      expect(job.state).to eq(:waiting)
    end

    context "when passed no block or command" do
      it "raises an error" do
        expect do
          LocalCI::Job.new(
            flow: @flow,
            name: "name",
            command: nil,
            block: nil
          )
        end.to raise_error(ArgumentError, "Must specify a block or command")
      end
    end

    it "defines a rake task" do
      LocalCI::Job.new(
        flow: @flow,
        name: "The Job Name!",
        command: "command",
        block: "block"
      )

      expect(Rake::Task.task_defined?("ci:flow:jobs:the_job_name")).to be(true)
    end

    it "gives the rake task the right prerequisite" do
      LocalCI::Job.new(
        flow: @flow,
        name: "The Job Name!",
        command: "command",
        block: "block"
      )

      expect(Rake::Task["ci:flow:jobs"].prerequisites).to include("ci:flow:jobs:the_job_name")
    end
  end

  describe "task" do
    context "when running a block" do
      it "runs all the commands from the block" do
        expect(LocalCI::Helper.runner).to receive(:run).with("command 1")
        expect(LocalCI::Helper.runner).to receive(:run).with("command", "2")

        LocalCI::Job.new(
          flow: @flow,
          name: "block task",
          command: nil,
          block: -> {
            run "command 1"
            run "command", "2"
          }
        )

        ::Rake::Task["ci:flow:jobs:block_task"].invoke
      end

      it "sets the state" do
        job = LocalCI::Job.new(
          flow: @flow,
          name: "block task",
          command: nil,
          block: -> {}
        )

        ::Rake::Task["ci:flow:jobs:block_task"].invoke

        expect(job.state).to eq(:success)
      end

      it "updates the output" do
        job = LocalCI::Job.new(
          flow: @flow,
          name: "block task",
          command: nil,
          block: -> {}
        )
        expect(@output).to receive(:update).with(job)

        ::Rake::Task["ci:flow:jobs:block_task"].invoke
      end
    end

    context "when running one command inline" do
      it "runs the commands" do
        expect(LocalCI::Helper.runner).to receive(:run).with("command", "by", "argument")

        LocalCI::Job.new(
          flow: @flow,
          name: "command task",
          command: ["command", "by", "argument"],
          block: nil
        )
        ::Rake::Task["ci:flow:jobs:command_task"].invoke
      end
    end

    context "when the job fails" do
      before do
        @job = LocalCI::Job.new(
          flow: @flow,
          name: "Raises an Error",
          command: "exit 1",
          block: nil
        )
      end

      it "is recorded against the flow" do
        expect(LocalCI::Helper.runner).to receive(:run).with("exit 1")
          .and_raise(
            TTY::Command::ExitError.new(
              "exit 1",
              double(
                exit_status: 1,
                err: "oops!",
                out: ""
              )
            )
          )

        ::Rake::Task["ci:flow:jobs:raises_an_error"].invoke

        expect(@flow.failures.size).to eq(1)
        expect(@flow.failures.first.job).to eq("Raises an Error")
      end

      it "sets the state" do
        ::Rake::Task["ci:flow:jobs:raises_an_error"].invoke

        expect(@job.state).to eq(:failed)
      end

      it "updates the output" do
        expect(@output).to receive(:update).with(@job)

        ::Rake::Task["ci:flow:jobs:raises_an_error"].invoke
      end
    end
  end
end
