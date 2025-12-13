module LocalCI
  class Failure
    attr_reader :job, :message

    def initialize(job:, message:)
      @job = job
      @message = message
    end
  end
end
