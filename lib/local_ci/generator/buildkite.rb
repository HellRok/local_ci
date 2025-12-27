module LocalCI
  module Generator
    module Buildkite
      def self.pipeline
        puts steps.to_yaml
      end

      def self.steps
        {
          "steps" => LocalCI.flows.flat_map do |flow|
            step = {}

            if flow.parallel?
              step["group"] = flow.heading
              step["steps"] = []

              flow.jobs.each do |job|
                step["steps"] << {
                  "label" => job.name,
                  "commands" => [
                    "bundle check &> /dev/null || bundle install",
                    "bundle exec rake #{job.task}"
                  ]
                }
              end

            else
              step["label"] = flow.heading
              step["commands"] = [
                "bundle check &> /dev/null || bundle install",
                "bundle exec rake #{flow.task}"
              ]
            end

            [step, "wait"]
          end
        }
      end
    end
  end
end
