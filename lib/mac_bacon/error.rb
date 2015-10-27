module Bacon
  class Error < RuntimeError
    attr_accessor :count_as

    def initialize(count_as, message)
      @count_as = count_as
      super message
    end

    def count_as_failure?
      @count_as == :failure
    end

    def count_as_error?
      @count_as == :error
    end
  end
end
