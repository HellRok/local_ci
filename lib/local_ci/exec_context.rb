module LocalCI
  class ExecContext
    def initialize(flow:)
      @flow = flow
    end

    def run(command, *args)
      LocalCI::Helper.runner.run command, *args
    end

    def job(name, *args, &block)
      LocalCI::Job.new(
        flow: @flow,
        name: name,
        command: args,
        block: block
      )
    end

    def setup(heading = nil, parallel: false, &block)
      heading ||= "#{@flow.heading} - Setup"
      LocalCI::Flow.new(
        name: "#{@flow.task}:setup",
        heading: heading,
        parallel: parallel,
        actions: false,
        block: block
      )
    end

    def teardown(heading = nil, parallel: false, &block)
      heading ||= "#{@flow.heading} - Teardown"
      LocalCI::Flow.new(
        name: "#{@flow.task}:teardown",
        heading: heading,
        parallel: parallel,
        actions: false,
        block: block
      )
    end
  end
end
