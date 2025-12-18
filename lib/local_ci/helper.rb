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
  end
end
