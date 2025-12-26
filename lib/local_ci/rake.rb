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
        puts "hello"
        LocalCI::Generator::Buildkite.pipeline
      end
    end
  end
end
