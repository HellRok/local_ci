module LocalCI
  module DSL
    def setup(heading = "Setup", parallel: true, &block)
      LocalCI::Flow.new(task: :setup, heading: heading, parallel: parallel, block: block)
    end

    def teardown(heading = "Teardown", parallel: true, &block)
      LocalCI::Flow.new(task: :teardown, heading: heading, parallel: parallel, block: block)
    end

    def flow(task, heading = nil, parallel: true, &block)
      heading ||= task
      task = LocalCI::Helper.taskize(heading) unless task.is_a?(Symbol)

      LocalCI::Flow.new(task: task, heading: heading, parallel: parallel, block: block)
    end
  end
end
