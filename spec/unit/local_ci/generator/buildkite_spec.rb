require "spec_helper"

describe LocalCI::Generator::Buildkite do
  describe ".steps" do
    it "returns a hash with all the jobs" do
      allow(LocalCI).to receive(:flows).and_return([
        double(
          :flow_1,
          heading: "Flow Heading 1",
          jobs: [
            double(
              :job_1,
              name: "Flow 1 Job 1",
              task: "flow-1-job-1-task"
            )
          ]
        ),
        double(
          :flow_2,
          heading: "Flow Heading 2",
          jobs: [
            double(
              :job_2,
              name: "Flow 2 Job 2",
              task: "flow-2-job-2-task"
            ),
            double(
              :job_3,
              name: "Flow 2 Job 3",
              task: "flow-2-job-3-task"
            )
          ]
        )
      ])

      expect(LocalCI::Generator::Buildkite.steps).to eq(
        {
          "steps" => [
            {
              "group" => "Flow Heading 1",
              "steps" => [
                {
                  "label" => "Flow 1 Job 1",
                  "commands" => [
                    "bundle check &> /dev/null || bundle install",
                    "bundle exec rake flow-1-job-1-task ci:teardown"
                  ]
                }
              ]
            },
            "wait",
            {
              "group" => "Flow Heading 2",
              "steps" => [
                {
                  "label" => "Flow 2 Job 2",
                  "commands" => [
                    "bundle check &> /dev/null || bundle install",
                    "bundle exec rake flow-2-job-2-task ci:teardown"
                  ]
                },
                {
                  "label" => "Flow 2 Job 3",
                  "commands" => [
                    "bundle check &> /dev/null || bundle install",
                    "bundle exec rake flow-2-job-3-task ci:teardown"
                  ]
                }
              ]
            },
            "wait"
          ]
        }
      )
    end
  end

  describe ".pipeline" do
    it "returns the steps as yaml" do
      steps = double(:steps)
      allow(LocalCI::Generator::Buildkite).to receive(:steps).and_return(steps)
      expect(LocalCI::Generator::Buildkite).to receive(:steps)

      expect(steps).to receive(:to_yaml).and_return("steps yaml")
      expect(LocalCI::Generator::Buildkite).to receive(:puts).with("steps yaml")

      LocalCI::Generator::Buildkite.pipeline
    end
  end
end
