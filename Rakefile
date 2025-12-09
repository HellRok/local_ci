require "standard/rake"
require "local_ci"

LocalCI::Rake.setup(self)

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
  setup do
    job "Specs Setup", "echo specs setup"
  end

  teardown do
    job "Specs Teardown", "echo specs teardown"
  end

  job "RSpec", "bundle exec rspec"
end

flow "Build" do
  setup do
    job "Start docker", "echo docker start"
  end

  Dir.glob("*").each do |file|
    job "Compile - #{file}" do
      run "echo", "gcc", file
    end
  end

  teardown do
    job "Stop Docker", "echo docker stop"
  end
end
