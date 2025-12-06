module LocalCI
  class Flow
    def pastel = @pastel ||= Pastel.new(enabled: TTY::Color.support?)
    def runner = @runner ||= TTY::Command.new(output: Logger.new("ci.log"))

    def initialize(name:, heading:, parallel:, block:)
      @task = "ci:#{name}"
      @parallel = parallel
      # @failures = []
      # @heading = heading
      # @job_spinner = TTY::Spinner::Multi.new(
      #   "[:spinner] #{pastel.bold.blue(heading)}",
      #   format: :classic,
      #   success_mark: pastel.green("✓"),
      #   error_mark: pastel.red("✗"),
      #   style: {
      #     top: "",
      #     middle: "    ",
      #     bottom: "    "
      #   }
      # )

      setup_expected_tasks

      # klass = parallel ? ::Rake::MultiTask : ::Rake::Task
      # @flow = klass.define_task(@task) do
      #   @failures.each do |failure|
      #     failure.display
      #   end

      #   abort pastel.red("#{@heading} failed, see CI.log for more.") if @failures.any?
      # end

      # @flow.comment = heading

      instance_exec(&block)
    end

    def job(name, *args, &block)
      LocalCI::Job.new(
        flow: self,
        name: name,
        command: args,
        block: block
      )
      # command = args

      # raise ArgumentError, "Must specify a block or command" unless command || block_given?
      # task = "#{@task}:#{title}"
      # spinner = job_spinner.register("[:spinner] #{title}")

      # ::Rake::Task.define_task(task) do
      #   spinner.auto_spin
      #   start = Time.now

      #   if block_given?
      #     instance_exec(&block)
      #   else
      #     run(*command)
      #   end

      #   took = Time.now - start
      #   spinner.success("(#{took.round(2)}s)")
      # rescue TTY::Command::ExitError => e
      #   spinner.error
      #   @failures << LocalCI::Failure.new(
      #     job: title,
      #     message: e.message
      #   )
      # end

      # @flow.prerequisites << task
    end

    def run(command, *args)
      runner.run command, *args
    end

    private

    def setup_expected_tasks
      ::Rake::Task.define_task("ci") unless ::Rake::Task.task_defined?("ci")
      ::Rake::Task.define_task("ci:setup") unless ::Rake::Task.task_defined?("ci:setup")
      ::Rake::Task.define_task("ci:teardown") unless ::Rake::Task.task_defined?("ci:teardown")
      ::Rake::Task.define_task("ci:failure_check") unless ::Rake::Task.task_defined?("ci:failure_check")
      ::Rake::Task.define_task("#{@task}:setup") unless ::Rake::Task.task_defined?("#{@task}:setup")

      klass = @parallel ? ::Rake::MultiTask : ::Rake::Task
      klass.define_task("#{@task}:jobs") unless ::Rake::Task.task_defined?("#{@task}:jobs")

      ::Rake::Task.define_task("#{@task}:teardown") unless ::Rake::Task.task_defined?("#{@task}:teardown")
      ::Rake::Task.define_task("#{@task}:failure_check") unless ::Rake::Task.task_defined?("#{@task}:failure_check")
      ::Rake::Task.define_task(@task) unless ::Rake::Task.task_defined?(@task)

      ::Rake::Task["ci"].prerequisites << "ci:setup"
      ::Rake::Task["ci"].prerequisites << "#{@task}:teardown"
      ::Rake::Task["ci"].prerequisites << "ci:teardown"
      ::Rake::Task["ci"].prerequisites << "ci:failure_check"

      ::Rake::Task[@task.to_s].prerequisites << "#{@task}:failure_check"
      ::Rake::Task["#{@task}:failure_check"].prerequisites << "#{@task}:teardown"
      ::Rake::Task["#{@task}:teardown"].prerequisites << "#{@task}:jobs"
      ::Rake::Task["#{@task}:jobs"].prerequisites << "#{@task}:setup"
    end
  end
end
