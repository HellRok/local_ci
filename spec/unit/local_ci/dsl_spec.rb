require "spec_helper"

describe LocalCI::DSL do
  before do
    @block = -> {}
  end

  describe ".flow" do
    it "calls LocalCI::Flow" do
      expect(LocalCI::Flow).to receive(:new).with(
        task: :task,
        heading: "heading",
        parallel: "parallel",
        block: @block
      )

      Support::DSLKlass.new.flow(:task, "heading", parallel: "parallel", &@block)
    end

    context "when only passed a heading" do
      it "converts the heading to a sensible task name" do
        expect(LocalCI::Flow).to receive(:new).with(
          task: :my_cool_task,
          heading: "My Cool Task!",
          parallel: true,
          block: @block
        )

        Support::DSLKlass.new.flow("My Cool Task!", &@block)
      end
    end
  end

  describe ".setup" do
    it "calls LocalCI::Flow" do
      expect(LocalCI::Flow).to receive(:new).with(
        task: :setup,
        heading: "Setup",
        parallel: "parallel",
        block: @block
      )

      Support::DSLKlass.new.setup(parallel: "parallel", &@block)
    end
  end

  describe ".teardown" do
    it "calls LocalCI::Flow" do
      expect(LocalCI::Flow).to receive(:new).with(
        task: :teardown,
        heading: "Teardown",
        parallel: "parallel",
        block: @block
      )

      Support::DSLKlass.new.teardown(parallel: "parallel", &@block)
    end
  end
end
