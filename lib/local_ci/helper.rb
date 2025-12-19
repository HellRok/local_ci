module LocalCI
  module Helper
    def self.color?
      TTY::Color.support?
    end

    def self.pastel
      @pastel ||= Pastel.new(enabled: color?)
    end

    def self.runner
      @runner ||= TTY::Command.new(color: color?, output: logger)
    end

    def self.logger
      return Logger.new($stdout) if ENV.has_key?("LOCAL_CI_LOG_TO_STDOUT")

      log_file = ci? ? $stdout : "logs/local_ci.log"
      log_file = ENV.fetch("LOCAL_CI_LOG_FILE", log_file)

      FileUtils.mkdir_p(File.dirname(log_file)) unless log_file == $stdout

      Logger.new(log_file)
    end

    def self.taskize(heading)
      heading.downcase.gsub(/\s/, "_").gsub(/[^\w]/, "").to_sym
    end

    def self.human_duration(time_span)
      seconds = time_span.dup
      minutes = (seconds / 60).to_i
      hours = minutes / 60

      seconds %= 60
      minutes %= 60

      if hours >= 1
        "#{hours}h #{minutes}m"

      elsif minutes >= 1
        "#{minutes}m #{seconds.floor}s"

      else
        "%.2fs" % seconds
      end
    end

    def self.ci?
      ENV.has_key?("CI")
    end

    def self.local?
      !ci?
    end
  end
end
