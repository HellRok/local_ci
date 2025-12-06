module LocalCI
  class Flow
    attr_reader :heading, :job_spinner

    def pastel = @pastel ||= Pastel.new(enabled: TTY::Color.support?)
    def runner = @runner ||= TTY::Command.new(output: Logger.new("ci.log"))

    def initialize(task:, heading:, parallel:, block:)
      @failures = []
      @task = "ci:#{task}"
      @heading = heading
      @job_spinner = TTY::Spinner::Multi.new(
        "[:spinner] #{pastel.bold.blue(heading)}",
        format: :classic,
        success_mark: pastel.green("✓"),
        error_mark: pastel.red("✗"),
        style: {
          top: "",
          middle: "    ",
          bottom: "    "
        }
      )

      ensure_ci_task_exists

      klass = parallel ? ::Rake::MultiTask : ::Rake::Task
      @flow = klass.define_task(@task) do
        @failures.each do |failure|
          failure.display
        end

        abort pastel.red("#{@heading} failed, see CI.log for more.") if @failures.any?
      end

      @flow.comment = heading
      ::Rake::Task[:ci].prerequisites << @task

      instance_exec(&block)
    end

    def job(title, *args, &block)
      command = args

      raise ArgumentError, "Must specify a block or command" unless command || block_given?
      task = "#{@task}:#{title}"
      spinner = job_spinner.register("[:spinner] #{title}")

      ::Rake::Task.define_task(task) do
        spinner.auto_spin
        start = Time.now

        if block_given?
          instance_exec(&block)
        else
          run(*command)
        end

        took = Time.now - start
        spinner.success("(#{took.round(2)}s)")
      rescue TTY::Command::ExitError => e
        spinner.error
        @failures << LocalCI::Failure.new(
          job: title,
          message: e.message
        )
      end

      @flow.prerequisites << task
    end

    def run(command, *args)
      runner.run command, *args
    end

    private

    def ensure_ci_task_exists
      ::Rake::Task.define_task(:ci) unless ::Rake::Task.task_defined?(:ci)
    end
  end
end
