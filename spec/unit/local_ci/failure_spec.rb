require "spec_helper"

describe LocalCI::Failure do
  describe "#message" do
    it "returns information about the failure" do
      pastel = double(:pastel)
      expect(LocalCI::Helper).to receive(:pastel).and_return(pastel)
      expect(pastel).to receive(:bold).and_return(pastel)
      expect(pastel).to receive(:red).with("FAIL:")
        .and_return("red")

      failure = LocalCI::Failure.new(
        job: "job",
        message: "message"
      )

      expect(failure.message).to eq(<<~STR)
        red job
        message

      STR
    end
  end
end
