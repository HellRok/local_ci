require "spec_helper"

describe LocalCI::Rake do
  describe ".setup" do
    before do
      @klass = double(:klass)
      allow(@klass).to receive(:send)
    end

    it "includes the DSL" do
      expect(@klass).to receive(:send).with(:include, LocalCI::DSL)

      LocalCI::Rake.setup(@klass)
    end

    it "creates a top level ci task" do
      expect(@klass).to receive(:send).with(:desc, "Run the CI suite locally")
      expect(@klass).to receive(:send).with(:task, :ci)

      LocalCI::Rake.setup(@klass)
    end
  end
end
