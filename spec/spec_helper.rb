require "rspec"
require "rake"

require "local_ci"

require "support/dsl_klass"

RSpec.configure do |config|
  config.after(:example) do
    Rake::Task.clear

    LocalCI::Helper.instance_variable_set(:@pastel, nil)
    LocalCI::Helper.instance_variable_set(:@runner, nil)

    LocalCI.flows.clear
  end
end
