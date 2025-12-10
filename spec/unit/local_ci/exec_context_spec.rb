require "spec_helper"

describe LocalCI::ExecContext do
  before do
    @block = -> {}
    @flow = double(
      :flow,
      task: "flow-task",
      heading: "flow-heading"
    )
    @context = LocalCI::ExecContext.new(flow: @flow)
  end

  describe "#initialize" do
    it "assigns the flow" do
      expect(@context.flow).to eq(@flow)
    end
  end

  describe "#run" do
    it "runs the commands" do
      expect(LocalCI::Helper.runner).to receive(:run)
        .with("command", "arg1", "arg2")

      @context.instance_exec {
        run "command", "arg1", "arg2"
      }
    end
  end

  describe "#setup" do
    it "creates a new flow" do
      expect(LocalCI::Flow).to receive(:new)
        .with(
          name: "flow-task:setup",
          heading: "flow-heading - Setup",
          parallel: false,
          actions: false,
          block: @block
        )

      block = @block
      @context.instance_exec {
        setup(&block)
      }
    end

    it "passes through heading and parallel" do
      expect(LocalCI::Flow).to receive(:new)
        .with(
          name: "flow-task:setup",
          heading: "Special Setup",
          parallel: "parallel",
          actions: false,
          block: @block
        )

      block = @block
      @context.instance_exec {
        setup(
          "Special Setup",
          parallel: "parallel",
          &block
        )
      }
    end
  end

  describe "#teardown" do
    it "creates a new flow" do
      expect(LocalCI::Flow).to receive(:new)
        .with(
          name: "flow-task:teardown",
          heading: "flow-heading - Teardown",
          parallel: false,
          actions: false,
          block: @block
        )

      block = @block
      @context.instance_exec {
        teardown(&block)
      }
    end

    it "passes through heading and parallel" do
      expect(LocalCI::Flow).to receive(:new)
        .with(
          name: "flow-task:teardown",
          heading: "Special Teardown",
          parallel: "parallel",
          actions: false,
          block: @block
        )

      block = @block
      @context.instance_exec {
        teardown(
          "Special Teardown",
          parallel: "parallel",
          &block
        )
      }
    end
  end
end
