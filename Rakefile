require "standard/rake"
require "local_ci"

LocalCI::Rake.setup(self)

def run_on(commands:, image:, platform: "linux/amd64")
  run "docker run " \
    "--rm " \
    "--tty " \
    "--pull always " \
    "--workdir /app " \
    "--env BUNDLE_PATH=/gems/#{image.tr(":", "_")}/#{platform} " \
    "--env BUNDLE_WITHOUT=development " \
    "--mount type=bind,source=.,target=/app " \
    "--mount type=volume,source=local_ci_specs_gems,target=/gems/ " \
    "--platform #{platform} " \
    "#{image} " \
    "bash -c \"#{commands.join(" && ")}\""
end

flow "Linting" do
  job "StandardRB", "bundle exec rake standard"
end

flow "Specs" do
  job "RSpec", "bundle exec rspec"
  job "RSpec - plain", "LOCAL_CI_STYLE=plain bundle exec rspec"
  job "RSpec - json", "LOCAL_CI_STYLE=json bundle exec rspec"
  job "RSpec - realtime", "LOCAL_CI_STYLE=realtime bundle exec rspec"
  job "Fail", "exit 1"
end

# %w[linux/386 linux/amd64 linux/arm/v7 linux/arm64].each do |platform|
#   flow "#{platform.split("/", 2).last}: MRI Ruby" do
#     %w[4.0 3.4 3.3 3.2 3.1 3.0 2.7].each do |version|
#       job "Ruby #{version}" do
#         run_on(
#           image: "ruby:#{version}",
#           platform: platform,
#           commands: [
#             "bundle check &> /dev/null || bundle install",
#             "bundle exec rspec"
#           ]
#         )
#       end
#     end
#   end
# end

# %w[linux/amd64 linux/arm64].each do |platform|
#   flow "#{platform.split("/", 2).last}: JRuby" do
#     %w[10 9].each do |version|
#       job "JRuby #{version}" do
#         run_on(
#           image: "jruby:#{version}",
#           platform: platform,
#           commands: [
#             "bundle check &> /dev/null || bundle install",
#             "bundle exec rspec"
#           ]
#         )
#       end
#     end
#   end
# end

task "ci:buildkite" do
  LocalCI::Generator::Buildkite.output
end
