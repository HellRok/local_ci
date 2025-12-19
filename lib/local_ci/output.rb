module LocalCI
  class Output
    attr_reader :job

    def initialize(flow:)
      @flow = flow
      @first_paint = true
      @start = 0
      @mutex = Mutex.new
    end

    def start_thread
      @thread = Thread.new {
        loop do
          @mutex.synchronize { draw(final: @thread_should_exit) }
          break if @thread_should_exit
          sleep 0.1
        end
      }
    end

    def finish
      @thread_should_exit = true
      @thread.join
    end

    def pastel
      LocalCI::Helper.pastel
    end

    def cursor
      TTY::Cursor
    end

    def screen
      TTY::Screen
    end

    def tty?
      $stdout.isatty
    end

    def passed?
      @flow.jobs.all?(&:success?)
    end

    def failed?
      @flow.failures.any?
    end

    def done?
      @flow.jobs.all?(&:done?)
    end

    def update(job)
      if tty?
        finish and return if done?

        return if @thread&.alive?

        start_thread
      else
        @job = job

        @mutex.synchronize { json_output }
      end
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

    def draw(final: false)
      if @first_paint
        @start = Time.now
        @first_paint = false
      else
        print cursor.clear_line + cursor.up(@flow.jobs.size + 2)
      end

      puts heading_line
      @flow.jobs.each { |job| puts job_line job }
      puts footer_line

      puts if final
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
        result << "[ ] "
      elsif job.running?
        result << "[-] "
      elsif job.success?
        result << "[#{pastel.green "✓"}] "
      elsif job.failed?
        result << "[#{pastel.red "✗"}] "
      end

      result << name

      result << " (#{pastel.yellow LocalCI::Helper.human_duration(job.duration)})" unless job.waiting?

      result
    end

    def duration
      LocalCI::Helper.human_duration(Time.now - @start)
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
