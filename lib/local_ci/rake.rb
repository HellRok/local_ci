module LocalCI
  module Rake
    def self.setup(klass)
      klass.send(:include, LocalCI::DSL)

      ci_task = LocalCI::Task["ci", "Run the CI suite"]
      LocalCI::Task["ci:setup", "Setup the system to run CI"]
      LocalCI::Task["ci:teardown", "Cleanup after the CI"]

      ci_task.add_prerequisite "ci:setup"
      ci_task.define do
        LocalCI::Task["ci:teardown"].invoke
      end

      LocalCI::Task["ci:generate:buildkite", "Prints the contents of a Buildkite pipeline.yml the CI suite"] do
        LocalCI::Generator::Buildkite.pipeline
      end

      LocalCI::Task["ci:generate:semaphore_ci", "Writes a .semaphore/semaphore.yml file for the CI suite"] do
        LocalCI::Generator::SemaphoreCI.pipeline
      end
    end
  end
end
