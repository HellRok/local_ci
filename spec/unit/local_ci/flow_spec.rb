require "spec_helper"

describe LocalCI::Flow do
  describe "#initialize" do
    it "creates the ci task" do
      LocalCI::Flow.new(task: "test", heading: "heading", parallel: true, block: -> {})

      expect(Rake::Task.task_defined?("ci")).to be(true)
    end

    it "creates a task prefixed with ci:" do
      LocalCI::Flow.new(task: "test", heading: "heading", parallel: true, block: -> {})

      expect(Rake::Task.task_defined?("ci:test")).to be(true)
    end
  end
end
