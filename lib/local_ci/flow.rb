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

    def parallel?
      @parallel
    end

    def isolated?
      !LocalCI::Task["ci"].already_invoked
    end

    def raise_failures
      LocalCI::Task["ci:teardown"].invoke
      output.failures

      abort LocalCI::Helper.pastel.red("#{@heading} failed, see ci.log for more.")
    end

    def setup_task
      "#{@task}:setup"
    end

    def jobs_task
      "#{@task}:jobs"
    end

    def teardown_task
      "#{@task}:teardown"
    end

    private

    def setup_required_tasks
      LocalCI::Task["ci"].add_prerequisite "ci:setup"
    end

    def setup_flow_tasks
      LocalCI::Task[setup_task]

      LocalCI::Task.new(jobs_task, parallel_prerequisites: @parallel)

      LocalCI::Task[teardown_task]
      LocalCI::Task[@task, @heading]

      LocalCI::Task[setup_task]
      LocalCI::Task[setup_task].add_prerequisite "ci:setup"

      LocalCI::Task[@task].add_prerequisite jobs_task
      LocalCI::Task[jobs_task].add_prerequisite setup_task

      LocalCI::Task["ci"].add_prerequisite @task

      LocalCI.flows << self
    end

    def setup_actionless_flow_tasks
      LocalCI::Task.new("#{@task}:jobs", parallel_prerequisites: @parallel)

      LocalCI::Task[@task].add_prerequisite "#{@task}:jobs"
    end

    def after_jobs
      LocalCI::Task[@task].define do
        LocalCI::Task[teardown_task].invoke
        LocalCI::Task["ci:teardown"].invoke unless !isolated? || actionless?

        raise_failures if @failures.any?
      end
    end
  end
end
