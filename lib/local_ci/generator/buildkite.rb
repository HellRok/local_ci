module LocalCI
  module Generator
    module Buildkite
      def self.output
        steps = LocalCI.flows.flat_map do |flow|
          step = {
            "group" => flow.heading,
            "steps" => []
          }

          flow.jobs.each do |job|
            step["steps"] << {
              "label" => job.name,
              "commands" => [
                "bundle check &> /dev/null || bundle install",
                "bundle exec rake #{job.task} ci:teardown"
              ]
            }
          end

          [step, "wait"]
        end

        puts({"steps" => steps}.to_yaml)
      end
    end
  end
end
