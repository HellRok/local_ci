module LocalCI
  module Rake
    def self.setup(klass)
      klass.send(:include, LocalCI::DSL)
    end
  end
end
