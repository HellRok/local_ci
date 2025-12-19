module LocalCI
  class Job
    attr_reader :flow, :name, :command, :block, :task, :state

    def initialize(flow:, name:, command:, block:)
      @flow = flow
      @flow.jobs << self
      @task = "#{@flow.task}:jobs:#{LocalCI::Helper.taskize(name)}"

      @command = command
      @block = block

      @name = name
      @state = :waiting

      raise ArgumentError, "Must specify a block or command" unless command || block

      ::Rake::Task.define_task(task) do
        @state = :running
        @flow.output.update(self)
        @start = Time.now

        if block
          LocalCI::ExecContext.new(flow: @flow).instance_exec(&block)
        else
          LocalCI::Helper.runner.run(*command)
        end
        @state = :success
      rescue TTY::Command::ExitError => e
        @state = :failed
        @flow.failures << LocalCI::Failure.new(
          job: @name,
          message: e.message
        )
      ensure
        @duration = duration
        @flow.output.update(self)
      end

      ::Rake::Task["#{@flow.task}:jobs"].prerequisites << task

      ::Rake::Task[task].prerequisites << "#{@flow.task}:setup" if @flow.actions?
    end

    def duration
      return if @start.nil?

      @duration || Time.now - @start
    end

    def waiting?
      @state == :waiting
    end

    def running?
      @state == :running
    end

    def success?
      @state == :success
    end

    def failed?
      @state == :failed
    end

    def done?
      [:success, :failed].include? @state
    end
  end
end
