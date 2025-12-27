require "spec_helper"

describe LocalCI::Generator::Buildkite do
  describe ".steps" do
    it "returns a hash with all the jobs" do
      allow(LocalCI).to receive(:flows).and_return([
        double(
          :flow_1,
          parallel?: true,
          heading: "Flow Heading 1",
          teardown_task: "ci:flow-1:teardown",
          jobs: [
            double(
              :job_1,
              name: "Flow 1 Job 1",
              task: "ci:flow-1-job-1-task"
            ),
            double(
              :job_2,
              name: "Flow 1 Job 2",
              task: "ci:flow-1-job-2-task"
            )
          ]
        ),
        double(
          :flow_2,
          parallel?: false,
          heading: "Flow Heading 2",
          task: "ci:flow-2",
          teardown_task: "ci:flow-2:teardown",
          jobs: [
            double(
              :job_3,
              name: "Flow 2 Job 1"
            ),
            double(
              :job_4,
              name: "Flow 2 Job 2"
            )
          ]
        )
      ])

      pipeline = LocalCI::Generator::Buildkite.steps
      steps = pipeline["steps"]

      expect(steps.size).to eq(4)

      flow_1 = steps[0]
      expect(flow_1["group"]).to eq("Flow Heading 1")
      expect(flow_1["steps"].size).to eq(2)
      expect(flow_1["steps"][0]).to eq(
        {
          "label" => "Flow 1 Job 1",
          "commands" => [
            "bundle check &> /dev/null || bundle install",
            "bundle exec rake ci:flow-1-job-1-task"
          ]
        }
      )
      expect(flow_1["steps"][1]).to eq(
        {
          "label" => "Flow 1 Job 2",
          "commands" => [
            "bundle check &> /dev/null || bundle install",
            "bundle exec rake ci:flow-1-job-2-task"
          ]
        }
      )
      expect(steps[1]).to eq("wait")

      flow_2 = steps[2]
      expect(flow_2["label"]).to eq("Flow Heading 2")
      expect(flow_2["commands"]).to eq(
        [
          "bundle check &> /dev/null || bundle install",
          "bundle exec rake ci:flow-2"
        ]
      )
      expect(steps[3]).to eq("wait")
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
