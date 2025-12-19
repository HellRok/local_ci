module LocalCI
  module Helper
    def self.color?
      TTY::Color.support?
    end

    def self.pastel
      @pastel ||= Pastel.new(enabled: color?)
    end

    def self.runner
      @runner ||= TTY::Command.new(color: color?, output: Logger.new("ci.log"))
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
