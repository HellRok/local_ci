require "spec_helper"

describe LocalCI::DSL do
  before do
    @block = -> {}
  end

  describe ".flow" do
    it "calls LocalCI::Flow" do
      expect(LocalCI::Flow).to receive(:new).with(
        name: :name,
        heading: "heading",
        parallel: "parallel",
        block: @block
      )

      Support::DSLKlass.new.flow(:name, "heading", parallel: "parallel", &@block)
    end

    context "when only passed a heading" do
      it "converts the heading to a sensible name name" do
        expect(LocalCI::Flow).to receive(:new).with(
          name: :my_cool_flow,
          heading: "My Cool Flow!",
          parallel: true,
          block: @block
        )

        Support::DSLKlass.new.flow("My Cool Flow!", &@block)
      end
    end
  end

  describe ".setup" do
    it "calls LocalCI::Flow" do
      expect(LocalCI::Flow).to receive(:new).with(
        name: :setup,
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
        name: :teardown,
        heading: "Teardown",
        parallel: "parallel",
        block: @block
      )

      Support::DSLKlass.new.teardown(parallel: "parallel", &@block)
    end
  end
end
