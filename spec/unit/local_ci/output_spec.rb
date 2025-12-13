require "spec_helper"

describe LocalCI::Output do
  before do
    @job = double(:job)
    @flow = double(:flow, jobs: [])
    @thread = double(:thread, alive?: true)
    allow(@thread).to receive(:join)

    @output = LocalCI::Output.new(flow: @flow)
    @output.instance_variable_set(:@thread, @thread)
  end

  describe "#update" do
    before do
      allow(@output).to receive(:output)
      allow(@output).to receive(:json_output)
    end

    context "when we are not in a TTY" do
      before do
        expect(@output).to receive(:tty?).and_return(false)
      end

      it "sets the job" do
        @output.update(@job)
        expect(@output.job).to eq(@job)
      end

      it "calls json_output" do
        expect(@output).to receive(:json_output)
        @output.update(@job)
      end
    end

    context "when we are in a TTY" do
      before do
        allow(@output).to receive(:tty?).and_return(true)
      end

      context "when all jobs are done" do
        before do
          allow(@output).to receive(:done?).and_return(true)
        end

        it "calls finish" do
          expect(@output).to receive(:finish)
          @output.update(@job)
        end

        it "does not call start_thread" do
          expect(@output).not_to receive(:start_thread)
          @output.update(@job)
        end
      end

      context "the thread is alive" do
        before do
          allow(@output).to receive(:done?).and_return(false)
        end

        it "does not call finish" do
          expect(@output).not_to receive(:finish)
          @output.update(@job)
        end

        it "does not call start_thread" do
          expect(@output).not_to receive(:start_thread)
          @output.update(@job)
        end
      end

      context "the thread is not alive" do
        before do
          allow(@output).to receive(:done?).and_return(false)
          allow(@thread).to receive(:alive?).and_return(false)
        end

        it "starts the thread" do
          expect(@output).to receive(:start_thread)

          @output.update(@job)
        end
      end
    end
  end

  describe "#failures" do
    before do
      allow(@flow).to receive(:failures).and_return(
        [
          double(:failure, job: "job-1", message: "message-1"),
          double(:failure, job: "job-2", message: "message-2")
        ]
      )
    end

    context "when we are in a TTY" do
      it "displays the errors" do
        expect(@output).to receive(:tty?).and_return(true)

        expect(@output).to receive(:puts).with(/job-1\nmessage-1/)
        expect(@output).to receive(:puts).with(/job-2\nmessage-2/)

        @output.failures
      end
    end

    context "when we are not in a TTY" do
      it "does nothing" do
        expect(@output).to receive(:tty?).and_return(false)

        expect(@output).not_to receive(:puts)

        @output.failures
      end
    end
  end

  describe "#draw" do
    before do
      allow(@output).to receive(:print)
      allow(@output).to receive(:puts)
      allow(@output).to receive(:heading_line).and_return("heading-line")
      allow(@output).to receive(:job_line).and_return("job-line")
      allow(@output).to receive(:footer_line).and_return("footer-line")

      allow(@flow).to receive(:jobs).and_return(["job-1", "job-2"])
    end

    context "on first paint for the flow" do
      before do
        @output.instance_variable_set(:@first_paint, true)
      end

      it "does not clear lines" do
        expect(TTY::Cursor).not_to receive(:clear_line)
        expect(TTY::Cursor).not_to receive(:up)

        @output.draw
      end

      it "sets the start time" do
        expect(Time).to receive(:now).and_return("time")

        @output.draw

        expect(@output.instance_variable_get(:@start)).to eq("time")
      end
    end

    context "on subsequent paints" do
      before do
        @output.instance_variable_set(:@first_paint, false)

        allow(TTY::Cursor).to receive(:clear_line).and_return("")
        allow(TTY::Cursor).to receive(:up).and_return("")
        allow(@output).to receive(:print)
      end

      it "moves up and clears the line" do
        expect(TTY::Cursor).to receive(:clear_line).and_return("clear-line")
        expect(TTY::Cursor).to receive(:up).with(4).and_return("up")

        expect(@output).to receive(:print).with("clear-lineup")

        @output.draw
      end
    end

    it "paints the heading" do
      expect(@output).to receive(:heading_line).and_return("heading-line")

      expect(@output).to receive(:puts).with("heading-line")

      @output.draw
    end

    it "paints the jobs" do
      expect(@output).to receive(:job_line).with("job-1").and_return("job-line-1")
      expect(@output).to receive(:job_line).with("job-2").and_return("job-line-2")

      expect(@output).to receive(:puts).with("job-line-1")
      expect(@output).to receive(:puts).with("job-line-2")

      @output.draw
    end

    it "paints the footer" do
      expect(@output).to receive(:footer_line).and_return("footer-line")

      expect(@output).to receive(:puts).with("footer-line")

      @output.draw
    end

    context "when final is true" do
      it "draws an extra new line" do
        expect(@output).to receive(:puts).with(no_args)

        @output.draw(final: true)
      end
    end
  end

  describe "#color" do
    before do
      @pastel = double(:pastel)
      allow(@output).to receive(:pastel).and_return(@pastel)
    end

    context "when the flow is running" do
      it "returns blue" do
        expect(@output).to receive(:passed?).and_return(false)
        expect(@output).to receive(:failed?).and_return(false)

        expect(@pastel).to receive(:blue).with("message")

        @output.color("message")
      end
    end

    context "when the flow has passed" do
      it "returns blue" do
        expect(@output).to receive(:passed?).and_return(true)

        expect(@pastel).to receive(:green).with("message")

        @output.color("message")
      end
    end

    context "when the flow has failed" do
      it "returns blue" do
        expect(@output).to receive(:passed?).and_return(false)
        expect(@output).to receive(:failed?).and_return(true)

        expect(@pastel).to receive(:red).with("message")

        @output.color("message")
      end
    end
  end

  describe "#heading_line" do
    before do
      allow(@flow).to receive(:heading).and_return("flow-heading")
      allow(@output).to receive(:screen).and_return(double(width: 40))
      @pastel = Pastel.new
    end

    it "returns a heading the width of the terminal" do
      expect(@pastel.strip(@output.heading_line)).to eq(
        "===| flow-heading |====================="
      )
    end

    context "when the heading is too long" do
      it "truncates it with an ellipsis" do
        allow(@flow).to receive(:heading).and_return("Some really long heading that really probably shouldn't be this long but is I guess")
        expect(@pastel.strip(@output.heading_line)).to eq(
          "===| Some really long heading that… |==="
        )
      end
    end

    context "when the heading is just short enough" do
      it "does not truncate" do
        allow(@flow).to receive(:heading).and_return("Something long, but not silly!")

        expect(@pastel.strip(@output.heading_line)).to eq(
          "===| Something long, but not silly! |==="
        )
      end
    end
  end

  describe "#job_line" do
    before do
      @pastel = Pastel.new

      @job = double(:job, name: "job-name")
      allow(@job).to receive(:waiting?).and_return(false)
      allow(@job).to receive(:running?).and_return(false)
      allow(@job).to receive(:success?).and_return(false)
      allow(@job).to receive(:failed?).and_return(false)

      allow(@output).to receive_message_chain(:cursor, :clear_line).and_return("")
      allow(@output).to receive(:screen).and_return(double(width: 20))
    end

    context "when the job is waiting" do
      it "returns no indicator and the job name" do
        expect(@job).to receive(:waiting?).and_return(true)
        expect(@pastel.strip(@output.job_line(@job))).to eq("[ ] job-name")
      end
    end

    context "when the job is running" do
      it "returns an indicator and the job name" do
        expect(@job).to receive(:running?).and_return(true)
        expect(@pastel.strip(@output.job_line(@job))).to eq("[-] job-name")
      end
    end

    context "when the job was successful" do
      it "returns an indicator and the job name" do
        expect(@job).to receive(:success?).and_return(true)
        expect(@pastel.strip(@output.job_line(@job))).to eq("[✓] job-name")
      end
    end

    context "when the job failed" do
      it "returns an indicator and the job name" do
        expect(@job).to receive(:failed?).and_return(true)
        expect(@pastel.strip(@output.job_line(@job))).to eq("[✗] job-name")
      end
    end

    context "when the name is too long" do
      it "truncates it with an ellipsis" do
        allow(@job).to receive(:waiting?).and_return(true)
        allow(@job).to receive(:name).and_return("A really long job name, obviously just way too long, what are you even doing!")

        expect(@pastel.strip(@output.job_line(@job))).to eq(
          "[ ] A really long jo…"
        )
      end
    end

    context "when the name is just short enough" do
      it "does not truncate" do
        allow(@job).to receive(:waiting?).and_return(true)
        allow(@job).to receive(:name).and_return("A long job name!!")

        expect(@pastel.strip(@output.job_line(@job))).to eq(
          "[ ] A long job name!!"
        )
      end
    end
  end

  describe "#footer_line" do
    before do
      allow(@output).to receive(:screen).and_return(double(width: 20))
      allow(@output).to receive(:duration).and_return("duration")
      @pastel = Pastel.new
    end

    it "returns a footer the length of the terminal with the duration" do
      expect(@pastel.strip(@output.footer_line)).to eq(
        "-------(duration)---"
      )
    end
  end

  describe "#duration" do
    context "when less than 60 seconds" do
      it "shows seconds with two decimal places" do
        @output.instance_variable_set(:@start, 5.567)
        allow(Time).to receive(:now).and_return(45)

        expect(@output.duration).to eq("39.43s")
      end
    end

    context "when less than 60 minutes" do
      it "shows the minutes and seconds" do
        @output.instance_variable_set(:@start, 10)
        allow(Time).to receive(:now).and_return(1240)

        expect(@output.duration).to eq("20m 30s")
      end
    end

    context "when greater than 60 minutes" do
      it "shows the hours and minutes" do
        @output.instance_variable_set(:@start, 10)
        allow(Time).to receive(:now).and_return(3800)

        expect(@output.duration).to eq("1h 3m")
      end
    end
  end

  describe "#json_output" do
    it "returns the state as json" do
      allow(@flow).to receive(:heading).and_return("flow-heading")
      @output.instance_variable_set(:@job, double(
        :job,
        name: "job-name",
        duration: "job-duration",
        state: "job-state"
      ))

      expect(@output).to receive(:puts).with({
        flow: "flow-heading",
        job: "job-name",
        duration: "job-duration",
        state: "job-state"
      }.to_json)

      @output.json_output
    end
  end
end
