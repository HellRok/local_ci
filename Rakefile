require "local_ci"

CHUNK = 15

desc "Run the CI suite locally"
task :local_ci

LocalCI.flow(:linting, "Linting") do
  job "StandardRB" do
    run "bundle exec standardrb"
  end
end

LocalCI.flow(:build, "Build") do
  CHUNK.times do |i|
    job "build-#{i}" do
      run "sleep 1"
    end
  end
end

LocalCI.flow(:lint, "Lint") do
  CHUNK.times do |i|
    job "lint-#{i}" do
      run "sleep 1"
      run "echo 'hi'"
    end
  end
end

namespace :standardrb do
  task :fix do
    `bundle exec standardrb --fix-unsafely`
  end
end
