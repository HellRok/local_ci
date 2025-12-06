module LocalCI
  module Rake
    def self.setup(klass)
      klass.send(:include, LocalCI::DSL)

      klass.send(:desc, "Run the CI suite locally")
      klass.send(:task, :ci)
    end
  end
end
