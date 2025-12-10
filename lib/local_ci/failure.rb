module LocalCI
  class Failure
    attr_reader :job

    def initialize(job:, message:)
      @job = job
      @message = message
    end

    def message
      <<~STR
        #{LocalCI::Helper.pastel.bold.red("FAIL:")} #{@job}
        #{@message}

      STR
    end
  end
end
