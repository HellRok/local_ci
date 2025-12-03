module LocalCI
  class Failure
    def pastel = @pastel ||= Pastel.new

    def initialize(job:, message:)
      @job = job
      @message = message
    end

    def display
      puts "#{pastel.bold.red("FAIL:")} #{@job}"
      puts @message
      puts
    end
  end
end
