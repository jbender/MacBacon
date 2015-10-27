module Bacon
  module Counter
    class << self
      def specifications_ran
        Bacon.specifications.select(&:finished?).size
      end

      def requirements_ran
        Bacon.requirements.size
      end

      def not_passed
        Bacon.specifications.select { |s| !s.passed? }.size
      end

      def failures
        Bacon.specifications.select(&:failure?).size
      end

      def errors
        Bacon.specifications.select(&:error?).size
      end
    end
  end
end
