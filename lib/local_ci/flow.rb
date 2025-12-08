module LocalCI
  class Flow
    attr_accessor :task, :heading, :spinner, :failures

    def initialize(name:, heading:, parallel:, block:)
      @task = "ci:#{name}"
      @parallel = parallel
      @failures = []
      @heading = heading
      @spinner = TTY::Spinner::Multi.new(
        "[:spinner] #{LocalCI::Helper.pastel.bold.blue(@heading)}",
        format: :classic,
        success_mark: LocalCI::Helper.pastel.green("✓"),
        error_mark: LocalCI::Helper.pastel.red("✗"),
        style: {
          top: "",
          middle: "    ",
          bottom: "    "
        }
      )

      setup_required_tasks
      if special?
        setup_special_flow_tasks
      else
        setup_flow_tasks
      end

      after_jobs

      instance_exec(&block)
    end

    def job(name, *args, &block)
      LocalCI::Job.new(
        flow: self,
        name: name,
        command: args,
        block: block
      )
    end

    def special?
      ["ci:setup", "ci:teardown"].include?(@task)
    end

    def isolated?
      LocalCI::Task["ci"].already_invoked
    end

    private

    def setup_required_tasks
      ci_task = LocalCI::Task["ci", "Run the CI suite"]

      LocalCI::Task["ci:setup", "Setup the system to run CI"]
      LocalCI::Task["ci:teardown", "Cleanup after the CI"]

      ci_task.add_prerequisite "ci:setup"
      ci_task.define do
        LocalCI::Task["ci:teardown"].invoke
      end
    end

    def setup_flow_tasks
      LocalCI::Task["#{@task}:setup"]

      LocalCI::Task.new("#{@task}:jobs", parallel_prerequisites: @parallel)

      LocalCI::Task["#{@task}:teardown"]
      LocalCI::Task["#{@task}:failure_check"]
      LocalCI::Task[@task, @heading]

      LocalCI::Task["#{@task}:setup"]
      LocalCI::Task["#{@task}:setup"].add_prerequisite "ci:setup"

      LocalCI::Task[@task].add_prerequisite "#{@task}:teardown"
      LocalCI::Task["#{@task}:failure_check"].add_prerequisite "#{@task}:teardown"
      LocalCI::Task["#{@task}:teardown"].add_prerequisite "#{@task}:jobs"
      LocalCI::Task["#{@task}:jobs"].add_prerequisite "#{@task}:setup"

      LocalCI::Task["ci"].add_prerequisite @task
    end

    def setup_special_flow_tasks
      LocalCI::Task.new("#{@task}:jobs", parallel_prerequisites: @parallel)
      LocalCI::Task["#{@task}:failure_check"]

      if @task == "ci:setup"
        LocalCI::Task[@task].comment = "Setup for the CI suite"

      elsif @task == "ci:teardown"
        LocalCI::Task[@task].comment = "Teardown for the CI suite"
      end

      LocalCI::Task[@task].add_prerequisite "#{@task}:failure_check"
      LocalCI::Task["#{@task}:failure_check"].add_prerequisite "#{@task}:jobs"
    end

    def after_jobs
      LocalCI::Task[@task].define do
        LocalCI::Task["#{@task}:teardown"].invoke
        LocalCI::Task["ci:teardown"].invoke unless isolated? || special?

        if @failures.any?
          LocalCI::Task["ci:teardown"].invoke
          @failures.each do |failure|
            failure.display
          end

          abort LocalCI::Helper.pastel.red("#{@heading} failed, see CI.log for more.")
        end
      end
    end
  end
end
