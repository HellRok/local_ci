module LocalCI
  module DSL
    def setup(heading = "Setup", parallel: false, &block)
      LocalCI::Flow.new(
        name: :setup,
        heading: heading,
        parallel: parallel,
        actions: false,
        block: block
      )
    end

    def teardown(heading = "Teardown", parallel: false, &block)
      LocalCI::Flow.new(
        name: :teardown,
        heading: heading,
        parallel: parallel,
        actions: false,
        block: block
      )
    end

    def flow(name, heading = nil, parallel: true, &block)
      heading ||= name
      name = LocalCI::Helper.taskize(heading) unless name.is_a?(Symbol)

      LocalCI::Flow.new(name: name, heading: heading, parallel: parallel, block: block)
    end

    def ci?
      LocalCI::Helper.ci?
    end

    def local?
      LocalCI::Helper.local?
    end
  end
end
