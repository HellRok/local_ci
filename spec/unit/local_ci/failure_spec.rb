require "spec_helper"

describe LocalCI::Failure do
  describe "#initialize" do
    it "sets up the instance variables" do
      failure = LocalCI::Failure.new(job: "job", message: "message")

      expect(failure.job).to eq("job")
      expect(failure.message).to eq("message")
    end
  end
end
