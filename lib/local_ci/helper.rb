module LocalCI
  module Helper
    def self.pastel = @pastel ||= Pastel.new(enabled: TTY::Color.support?)
    def self.runner = @runner ||= TTY::Command.new(output: Logger.new("ci.log"))

    def self.taskize(heading)
      heading.downcase.gsub(/\s/, "_").gsub(/[^\w]/, "").to_sym
    end
  end
end
