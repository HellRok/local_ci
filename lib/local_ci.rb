require "logger"
require "tty-command"
require "tty-spinner"
require "pastel"

require "local_ci/failure"
require "local_ci/flow"

module LocalCI
  def self.flow(task, heading, parallel: true, &block)
    LocalCI::Flow.new(task: task, heading: heading, parallel: parallel, block: block)
  end
end
