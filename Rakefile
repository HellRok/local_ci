require "standard/rake"
require "local_ci"

LocalCI::Rake.setup(self)

def run_on(commands:, image:, platform: "linux/amd64")
  run "docker run " \
    "--tty " \
    "--workdir /app " \
    "--mount type=bind,source=.,target=/app " \
    "--platform #{platform} " \
    "#{image} " \
    "bash -c \"#{commands.join(" && ")}\""
end

setup do
  job "Bundle", "bundle check || bundle install"
end

flow "Linting" do
  job "StandardRB", "bundle exec rake standard"
end

flow "Specs" do
  job "RSpec", "bundle exec rspec"
  job "RSpec - plain", "LOCAL_CI_STYLE=plain bundle exec rspec"
  job "RSpec - json", "LOCAL_CI_STYLE=json bundle exec rspec"
  job "RSpec - realtime", "LOCAL_CI_STYLE=realtime bundle exec rspec"
end

flow "MRI Ruby" do
  %w[linux/amd64 linux/arm64].each do |platform|
    %w[4.0-rc 3.4 3.3 3.2 3.1 3.0 2.7].each do |version|
      job "[#{platform.split("/").last}] Ruby #{version}" do
        run_on(
          image: "ruby:#{version}",
          platform: platform,
          commands: [
            "bundle config set --local without development",
            "bundle install",
            "bundle exec rspec",
            "LOCAL_CI_STYLE=plain bundle exec rspec",
            "LOCAL_CI_STYLE=json bundle exec rspec",
            "LOCAL_CI_STYLE=realtime bundle exec rspec"
          ]
        )
      end
    end
  end
end

flow "JRuby" do
  %w[linux/amd64 linux/arm64].each do |platform|
    %w[10 9].each do |version|
      job "[#{platform.split("/").last}] JRuby #{version}" do
        run_on(
          image: "jruby:#{version}",
          commands: [
            "bundle config set --local without development",
            "bundle install",
            "bundle exec rspec",
            "LOCAL_CI_STYLE=plain bundle exec rspec",
            "LOCAL_CI_STYLE=json bundle exec rspec",
            "LOCAL_CI_STYLE=realtime bundle exec rspec"
          ]
        )
      end
    end
  end
end
