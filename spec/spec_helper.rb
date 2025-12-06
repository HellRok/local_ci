require "rspec"
require "rake"

require "local_ci"

require "support/dsl_klass"

RSpec.configure do |config|
  config.after(:example) do
    Rake::Task.clear
  end
end
