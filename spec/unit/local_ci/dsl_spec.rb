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
        actions: false,
        block: @block
      )

      Support::DSLKlass.new.setup(parallel: "parallel", &@block)
    end

    it "passes through the heading" do
      expect(LocalCI::Flow).to receive(:new).with(
        name: :setup,
        heading: "My Cool Setup",
        parallel: "parallel",
        actions: false,
        block: @block
      )

      Support::DSLKlass.new.setup("My Cool Setup", parallel: "parallel", &@block)
    end
  end

  describe ".teardown" do
    it "calls LocalCI::Flow" do
      expect(LocalCI::Flow).to receive(:new).with(
        name: :teardown,
        heading: "Teardown",
        parallel: "parallel",
        actions: false,
        block: @block
      )

      Support::DSLKlass.new.teardown(parallel: "parallel", &@block)
    end

    it "passes through the heading" do
      expect(LocalCI::Flow).to receive(:new).with(
        name: :teardown,
        heading: "My Cool Teardown",
        parallel: "parallel",
        actions: false,
        block: @block
      )

      Support::DSLKlass.new.teardown("My Cool Teardown", parallel: "parallel", &@block)
    end
  end

  describe ".ci?" do
    it "calls LocalCI::Helper" do
      expect(LocalCI::Helper).to receive(:ci?)

      Support::DSLKlass.new.ci?
    end
  end

  describe ".local?" do
    it "calls LocalCI::Helper" do
      expect(LocalCI::Helper).to receive(:local?)

      Support::DSLKlass.new.local?
    end
  end
end
