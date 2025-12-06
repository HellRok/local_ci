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

      setup_expected_tasks

      define_failure_check

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
      ::Rake::Task["ci"].prerequisites << "#{@task}:failure_check"
      ::Rake::Task["ci"].prerequisites << "ci:teardown"
      ::Rake::Task["ci"].prerequisites << "ci:failure_check"

      ::Rake::Task[@task].prerequisites << "#{@task}:failure_check"
      ::Rake::Task["#{@task}:failure_check"].prerequisites << "#{@task}:teardown"
      ::Rake::Task["#{@task}:teardown"].prerequisites << "#{@task}:jobs"
      ::Rake::Task["#{@task}:jobs"].prerequisites << "#{@task}:setup"
    end

    def define_failure_check
      ::Rake::Task.define_task("#{@task}:failure_check") do
        @failures.each do |failure|
          failure.display
        end

        abort LocalCI::Helper.pastel.red("#{@heading} failed, see CI.log for more.") if @failures.any?
      end
    end
  end
end
