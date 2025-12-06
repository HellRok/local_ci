module LocalCI
  module DSL
    def setup(heading = "Setup", parallel: true, &block)
      LocalCI::Flow.new(name: :setup, heading: heading, parallel: parallel, block: block)
    end

    def teardown(heading = "Teardown", parallel: true, &block)
      LocalCI::Flow.new(name: :teardown, heading: heading, parallel: parallel, block: block)
    end

    def flow(name, heading = nil, parallel: true, &block)
      heading ||= name
      name = LocalCI::Helper.taskize(heading) unless name.is_a?(Symbol)

      LocalCI::Flow.new(name: name, heading: heading, parallel: parallel, block: block)
    end
  end
end
