module LocalCI
  class Flow
    attr_accessor :task, :heading, :spinner, :failures, :jobs, :output

    def initialize(name:, heading:, parallel:, block:, actions: true)
      @task = name
      @task = "ci:#{name}" unless @task.start_with?("ci:")
      @parallel = parallel
      @failures = []
      @actions = actions

      @heading = heading
      @jobs = []
      @output = LocalCI::Output.new(flow: self)

      setup_required_tasks
      if actions?
        setup_flow_tasks
      else
        setup_actionless_flow_tasks
      end

      after_jobs

      LocalCI::ExecContext.new(flow: self).instance_exec(&block)
    end

    def actions?
      !!@actions
    end

    def actionless?
      !actions?
    end

    def isolated?
      !LocalCI::Task["ci"].already_invoked
    end

    def raise_failures
      LocalCI::Task["ci:teardown"].invoke
      output.failures

      abort LocalCI::Helper.pastel.red("#{@heading} failed, see ci.log for more.")
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
      LocalCI::Task[@task, @heading]

      LocalCI::Task["#{@task}:setup"]
      LocalCI::Task["#{@task}:setup"].add_prerequisite "ci:setup"

      LocalCI::Task[@task].add_prerequisite "#{@task}:teardown"
      LocalCI::Task["#{@task}:teardown"].add_prerequisite "#{@task}:jobs"
      LocalCI::Task["#{@task}:jobs"].add_prerequisite "#{@task}:setup"

      LocalCI::Task["ci"].add_prerequisite @task

      LocalCI.flows << self
    end

    def setup_actionless_flow_tasks
      LocalCI::Task.new("#{@task}:jobs", parallel_prerequisites: @parallel)

      LocalCI::Task[@task].add_prerequisite "#{@task}:jobs"
    end

    def after_jobs
      LocalCI::Task[@task].define do
        LocalCI::Task["#{@task}:teardown"].invoke
        LocalCI::Task["ci:teardown"].invoke unless !isolated? || actionless?

        raise_failures if @failures.any?
      end
    end
  end
end
