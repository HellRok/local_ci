require "spec_helper"

describe LocalCI::Generator::SemaphoreCI do
  describe ".blocks" do
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

      pipeline = LocalCI::Generator::SemaphoreCI.blocks
      expect(pipeline["version"]).to eq("v1.0")
      expect(pipeline["name"]).to eq("CI")
      expect(pipeline["agent"]).to eq(
        {
          "machine" => {
            "type" => "f1-standard-2",
            "os_image" => "ubuntu2404"
          }
        }
      )

      blocks = pipeline["blocks"]
      expect(blocks.size).to eq(2)

      flow_1 = blocks[0]
      expect(flow_1["name"]).to eq("Flow Heading 1")
      expect(flow_1["task"]["jobs"].size).to eq(2)
      expect(flow_1["task"]["jobs"][0]).to eq(
        {
          "name" => "Flow 1 Job 1",
          "commands" => [
            "checkout",
            "bundle check &> /dev/null || bundle install",
            "bundle exec rake ci:flow-1-job-1-task ci:flow-1:teardown ci:teardown"
          ]
        }
      )
      expect(flow_1["task"]["jobs"][1]).to eq(
        {
          "name" => "Flow 1 Job 2",
          "commands" => [
            "checkout",
            "bundle check &> /dev/null || bundle install",
            "bundle exec rake ci:flow-1-job-2-task ci:flow-1:teardown ci:teardown"
          ]
        }
      )

      flow_2 = blocks[1]
      expect(flow_2["name"]).to eq("Flow Heading 2")
      expect(flow_2["task"]["jobs"].size).to eq(1)
      expect(flow_2["task"]["jobs"][0]).to eq(
        {
          "name" => "Flow Heading 2",
          "commands" => [
            "checkout",
            "bundle check &> /dev/null || bundle install",
            "bundle exec rake ci:flow-2"
          ]
        }
      )
    end
  end

  describe ".pipeline" do
    it "returns the blocks as yaml" do
      blocks = double(:blocks)
      allow(LocalCI::Generator::SemaphoreCI).to receive(:blocks).and_return(blocks)
      expect(LocalCI::Generator::SemaphoreCI).to receive(:blocks)

      expect(blocks).to receive(:to_yaml).and_return("blocks yaml")
      expect(FileUtils).to receive(:mkdir_p).with(".semaphore")
      expect(File).to receive(:write).with(".semaphore/semaphore.yml", "blocks yaml")

      LocalCI::Generator::SemaphoreCI.pipeline
    end
  end
end
