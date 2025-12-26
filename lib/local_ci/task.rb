module LocalCI
  class Task
    extend Forwardable

    def self.[](task, comment = nil, &block)
      new_task = new(task, comment: comment)
      new_task.define(&block) if block_given?
      new_task
    end

    attr_accessor :task

    def_delegators :@task, :comment=, :invoke, :already_invoked, :prerequisites

    def initialize(task, comment: nil, parallel_prerequisites: false)
      @parallel_prerequisites = parallel_prerequisites
      klass.define_task(task) unless klass.task_defined?(task)
      @task = klass[task]
      @task.comment = comment if comment
    end

    def add_prerequisite(prerequisite)
      return if prerequisites.include?(prerequisite)
      prerequisites << prerequisite
    end

    def define(&block)
      ::Rake::Task.define_task(@task.to_s) do
        block.call
      end
    end

    private

    def klass
      @parallel_prerequisites ? ::Rake::MultiTask : ::Rake::Task
    end
  end
end
