module LocalCI
  module Generator
    module SemaphoreCI
      def self.pipeline
        FileUtils.mkdir_p(".semaphore")
        File.write(".semaphore/semaphore.yml", blocks.to_yaml)
      end

      def self.blocks
        {
          "version" => "v1.0",
          "name" => "CI",
          "agent" => {
            "machine" => {
              "type" => "f1-standard-2",
              "os_image" => "ubuntu2404"
            }
          },

          "blocks" => LocalCI.flows.flat_map do |flow|
            block = {
              "name" => flow.heading,
              "task" => {"jobs" => []}
            }

            if flow.parallel?
              flow.jobs.each do |job|
                block["task"]["jobs"] << {
                  "name" => job.name,
                  "commands" => [
                    "checkout",
                    "bundle check &> /dev/null || bundle install",
                    "bundle exec rake #{job.task} #{flow.teardown_task} ci:teardown"
                  ]
                }
              end

            else
              block["task"]["jobs"] << {
                "name" => flow.heading,
                "commands" => [
                  "checkout",
                  "bundle check &> /dev/null || bundle install",
                  "bundle exec rake #{flow.task}"
                ]
              }
            end

            block
          end
        }
      end
    end
  end
end
