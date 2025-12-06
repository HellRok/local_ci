module LocalCI
  class Failure
    attr_accessor :job, :message
    def initialize(job:, message:)
      @job = job
      @message = message
    end

    def display
      puts "#{LocalCI::Helper.pastel.bold.red("FAIL:")} #{@job}"
      puts @message
      puts
    end
  end
end
