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
end
