module LocalCI
  class Job
    attr_accessor :flow, :name, :command, :block, :task, :spinner

    def initialize(flow:, name:, command:, block:)
      @flow = flow
      @name = name
      @command = command
      @block = block
      @task = "#{@flow.task}:jobs:#{LocalCI::Helper.taskize(name)}"

      raise ArgumentError, "Must specify a block or command" unless command || block
      @spinner = flow.spinner.register("[:spinner] #{name}")

      ::Rake::Task.define_task(task) do
        @spinner.auto_spin
        start = Time.now

        if block
          LocalCI::ExecContext.new(flow: @flow).instance_exec(&block)
        else
          LocalCI::Helper.runner.run(*command)
        end

        took = Time.now - start
        @spinner.success("(#{took.round(2)}s)")
      rescue TTY::Command::ExitError => e
        spinner.error
        @flow.failures << LocalCI::Failure.new(
          job: @name,
          message: e.message
        )
      end

      ::Rake::Task["#{@flow.task}:jobs"].prerequisites << task

      ::Rake::Task[task].prerequisites << "#{@flow.task}:setup" if @flow.actions?
    end
  end
end
