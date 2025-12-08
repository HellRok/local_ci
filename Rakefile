require "standard/rake"
require "local_ci"

LocalCI::Rake.setup(self)

# ci { ci:teardown }
#   -> ci:setup
#   -> ci:linting
#
# ci:teardown { failure_check } -> ci:teardown:jobs
# ci:teardown:jobs
#   -> ci:teardown:jobs:echo
#
# ci:linting { failure_check ci:teardown? }-> ci:linting:teardown
# ci:linting:teardown -> ci:linting:jobs
# ci:linting:jobs
#   -> ci:linting:setup
#   -> ci:linting:jobs:standardrb -> ci:linting:setup
# ci:linting:setup -> ci:setup
#
# ci:setup { failure_check } -> ci:setup:jobs
# ci:setup:jobs
#   -> ci:setup:jobs:bundle

setup do
  job "Bundle", "bundle check | bundle install"
end

teardown do
  job "Echo", "echo", "global teardown"
end

flow "Linting" do
  job "StandardRB", "bundle exec rake standard"
end

flow "Specs" do
  job "RSpec", "bundle exec rspec"
end

flow "Build" do
  # setup do
  #   job "Start docker", "echo docker start"
  # end

  Dir.glob("*").each do |file|
    job "Compile - #{file}" do
      run "echo", "gcc", file
    end
  end

  # teardown do
  #   job "Stop Docker", "echo docker stop"
  # end
end
