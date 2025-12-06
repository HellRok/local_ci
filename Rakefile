require "local_ci"

LocalCI::Rake.setup(self)

# ci:teardown
#
# ci:linting:failure_check
# ci:linting:teardown
# ci:linting:standardrb
# ci:linting:setup
#
# ci:build:failure_check
# ci:build:teardown
# ci:build:jobs
# ci:build:jobs:file1
# ci:build:jobs:file2
# ci:build:jobs:file3
# ci:build:jobs:file4
# ci:build:jobs:file5
# ci:build:setup
#
# ci:setup

# setup do
#   job "Bundle", "bundle check | bundle install"
# end
#
# teardown do
#   job "Echo", "echo", "global teardown"
# end

flow("Linting") do
  # Single line variant
  job "StandardRB", "bundle exec standardrb"
end

flow("Specs") do
  # Single line variant
  job "RSpec", "bundle exec rspec"
end

flow("Build") do
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

namespace :standardrb do
  task :fix do
    sh "bundle exec standardrb --fix-unsafely"
  end
end

# CHUNK = 15
#
# desc "Run the CI suite locally"
# task :local_ci
#
# LocalCI.flow(:linting, "Linting") do
#   job "StandardRB" do
#     run "bundle exec standardrb"
#   end
# end
#
# LocalCI.flow(:build, "Build") do
#   CHUNK.times do |i|
#     job "build-#{i}" do
#       run "sleep 1"
#     end
#   end
# end
#
# LocalCI.flow(:lint, "Lint") do
#   CHUNK.times do |i|
#     job "lint-#{i}" do
#       run "sleep 1"
#       run "echo 'hi'"
#     end
#   end
# end

namespace :standardrb do
  task :fix do
    sh "bundle exec standardrb --fix-unsafely"
  end
end
