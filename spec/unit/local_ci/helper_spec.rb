require "spec_helper"

describe LocalCI::Helper do
  describe ".pastel" do
    it "returns a Pastel instance" do
      expect(TTY::Color).to receive(:support?).and_return("support")
      expect(Pastel).to receive(:new).with(enabled: "support")
        .and_return("pastel")

      expect(LocalCI::Helper.pastel).to eq("pastel")
    end
  end

  describe ".runner" do
    it "returns a TTY::Command instance" do
      expect(TTY::Color).to receive(:support?).and_return("support")
      expect(Logger).to receive(:new).with("ci.log").and_return("logger")
      expect(TTY::Command).to receive(:new)
        .with(color: "support", output: "logger")
        .and_return("tty-command")

      expect(LocalCI::Helper.runner).to eq("tty-command")
    end
  end

  describe ".taskize" do
    it "returns a task-ized version of a string" do
      expect(LocalCI::Helper.taskize("Hello There!")).to eq(:hello_there)
    end
  end

  describe ".human_duration" do
    context "when less than 60 seconds" do
      it "shows seconds with two decimal places" do
        expect(LocalCI::Helper.human_duration(39.427)).to eq("39.43s")
      end

      it "shows seconds with two decimal places even if it's exactly a second" do
        expect(LocalCI::Helper.human_duration(40)).to eq("40.00s")
      end
    end

    context "when less than 60 minutes" do
      it "shows the minutes and seconds" do
        expect(LocalCI::Helper.human_duration(1230.1)).to eq("20m 30s")
      end
    end

    context "when greater than 60 minutes" do
      it "shows the hours and minutes" do
        expect(LocalCI::Helper.human_duration(3790.1)).to eq("1h 3m")
      end
    end
  end

  describe ".ci?" do
    context "when the CI env variable is set" do
      it "returns true" do
        allow(ENV).to receive(:has_key?).with("CI").and_return(true)

        expect(LocalCI::Helper.ci?).to be(true)
      end
    end

    context "when the CI env variable is not set" do
      it "returns false" do
        allow(ENV).to receive(:has_key?).with("CI").and_return(false)

        expect(LocalCI::Helper.ci?).to be(false)
      end
    end
  end

  describe ".local?" do
    it "returns the inverse of ci?" do
      allow(LocalCI::Helper).to receive(:ci?).and_return(true)

      expect(LocalCI::Helper.local?).to be(false)

      allow(LocalCI::Helper).to receive(:ci?).and_return(false)

      expect(LocalCI::Helper.local?).to be(true)
    end
  end
end
