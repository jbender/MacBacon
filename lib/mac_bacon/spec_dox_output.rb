require_relative "counter"

module Bacon
  # TODO for now we'll just use dots, which works best in a concurrent env
  module SpecDoxOutput
    def handle_context_begin(context)
      # Nested contexts do _not_ have an extra line between them and their parent.
      #puts if context.context_depth == 1

      #spaces = "  " * (context.context_depth - 1)
      #puts spaces + context.name
    end

    def handle_context_end(context)
    end

    def handle_specification_begin(specification)
      #spaces = "  " * (specification.context.class.context_depth - 1)
      ##print "#{spaces}  - #{specification.description}"
      #puts "#{spaces}  - #{specification.description}"
    end

    def handle_specification_end(error)
      #puts error.empty? ? "" : " [#{error}]"
      print '.'
    end

    def summary
      "%d specifications (%d requirements), %d failures, %d errors" %
        [Counter.specifications_ran, Counter.requirements_ran, Counter.failures, Counter.errors]
    end

    def handle_summary
      if Bacon.backtraces
        puts
        puts
        Bacon.specifications.each do |spec|
          unless spec.passed?
            puts spec.error_log
            puts
          end
        end
      end
      puts "Took: %.6f seconds." % (Time.now - @timer).to_f
      @timer = nil
      puts
      puts summary
    end
  end
end
