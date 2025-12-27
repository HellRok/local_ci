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

    it "sets up the local ci tasks" do
      LocalCI::Rake.setup(@klass)

      expect(::Rake::Task.task_defined?("ci")).to be(true)
      expect(::Rake::Task["ci"].comment).to eq("Run the CI suite")
      expect(::Rake::Task.task_defined?("ci:setup")).to be(true)
      expect(::Rake::Task["ci:setup"].comment).to eq("Setup the system to run CI")
      expect(::Rake::Task.task_defined?("ci:teardown")).to be(true)
      expect(::Rake::Task["ci:teardown"].comment).to eq("Cleanup after the CI")
    end

    it "sets up the CI generators" do
      LocalCI::Rake.setup(@klass)

      expect(::Rake::Task.task_defined?("ci:generate:buildkite")).to be(true)
      expect(::Rake::Task["ci:generate:buildkite"].comment).to eq("Prints the contents of a Buildkite pipeline.yml the CI suite")

      expect(::Rake::Task.task_defined?("ci:generate:semaphore_ci")).to be(true)
      expect(::Rake::Task["ci:generate:semaphore_ci"].comment).to eq("Writes a .semaphore/semaphore.yml file for the CI suite")
    end

    it "sets up the prerequisites" do
      LocalCI::Rake.setup(@klass)

      expect(::Rake::Task["ci"].prerequisites).to eq(["ci:setup"])
    end
  end
end
