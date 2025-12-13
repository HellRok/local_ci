module LocalCI
  class Output
    attr_reader :job

    def initialize(flow:)
      @flow = flow
      @first_paint = true
      @start = 0
      @mutex = Mutex.new
    end

    def pastel = LocalCI::Helper.pastel
    def cursor = TTY::Cursor
    def screen = TTY::Screen
    def tty? = $stdout.isatty

    def passed? = @flow.jobs.all?(&:success?)
    def failed? = @flow.failures.any?
    def done? = @flow.jobs.all?(&:done?)

    def update(job)
      @job = job

      @mutex.synchronize {
        tty? ? output : json_output
      }
    end

    def failures
      return unless tty?

      @mutex.synchronize {
        @flow.failures.each do |failure|
          puts <<~STR
            #{pastel.bold.red("FAIL:")} #{failure.job}
            #{failure.message}

          STR
        end
      }
    end

    def output
      if @first_paint
        @start = Time.now
        @first_paint = false
      else
        print cursor.clear_line + cursor.up(@flow.jobs.size + 2)
      end

      puts heading_line
      @flow.jobs.each { puts job_line it }
      puts footer_line
    end

    def color(message)
      if passed?
        pastel.green(message)
      elsif failed?
        pastel.red(message)
      else
        pastel.blue(message)
      end
    end

    def heading_line
      heading = @flow.heading.dup
      heading = "#{heading[...(screen.width - 11)]}…" if heading.length > (screen.width - 10)

      tail_length = screen.width - 5 - heading.length - 2

      color "===| #{pastel.bold heading} |#{"=" * tail_length}"
    end

    def job_line(job)
      name = job.name.dup

      name = "#{name[...(screen.width - 4)]}…" if name.length > (screen.width - 3)

      result = cursor.clear_line
      if job.waiting?
        result << "[ ] #{name}"
      elsif job.running?
        result << "[-] #{name}"
      elsif job.success?
        result << "[#{pastel.green "✓"}] #{name}"
      elsif job.failed?
        result << "[#{pastel.red "✗"}] #{name}"
      end

      result
    end

    def duration
      seconds = Time.now - @start
      minutes = seconds / 60
      hours = minutes / 60

      seconds %= 60
      minutes %= 60

      if hours >= 1
        "#{hours}h #{minutes}m"

      elsif minutes >= 1
        "#{minutes}m #{seconds}s"

      else
        "#{seconds.round(2)}s"
      end
    end

    def footer_line
      start_length = screen.width - 4 - duration.size - 1
      color "#{"-" * start_length}(#{pastel.bold duration})---"
    end

    def json_output
      puts({
        flow: @flow.heading,
        job: @job.name,
        duration: @job.duration,
        state: @job.state
      }.to_json)
    end
  end
end
