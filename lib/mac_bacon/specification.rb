module Bacon
  class Specification
    attr_reader :description, :context
    attr_accessor :delegate

    def initialize(context_class, description, block, before_filters, after_filters)
      @context = context_class.new(self)
      @description, @block = description, block
      @before_filters, @after_filters = before_filters.dup, after_filters.dup

      @finished = false

      Bacon.specifications << self
    end

    def delegate
      # Add the ability to override, but don't cache Bacon.delegate here so it
      # can be changed for all Specification instances from Bacon.delegate.
      @delegate || Bacon.delegate
    end

    def run
      @timer = NSTimer.scheduledTimerWithTimeInterval(@context.class.timeout,
                                               target:self,
                                             selector:'timedout!',
                                             userInfo:nil,
                                              repeats:false)

      #Bacon.dispatch_on_main_thread do
      Dispatch::Queue.main.async do
        Bacon.handle_specification_begin(self)
        if delegate.respond_to?('bacon_specification_will_start:')
          delegate.bacon_specification_will_start(self)
          #delegate.performSelectorOnMainThread('bacon_specification_will_start:', withObject:self, waitUntilDone:true)
        end
      end

      @before_filters.each { |f| @context.instance_eval(&f) }
      @number_of_requirements_before = Bacon.requirements.size
      @context.instance_eval(&@block)

      if passed? && Bacon.requirements.size == @number_of_requirements_before
        # the specification did not contain any requirements, so it flunked
        raise Error.new(:missing, "empty specification: #{full_name}")
      end

    rescue Object => e
      @exception = e
    ensure
      begin
        @after_filters.each { |f| @context.instance_eval(&f) }
      rescue Object => e
        @exception = e
      ensure
        @timer.invalidate
        @finished = true
        #Bacon.dispatch_on_main_thread do
        Dispatch::Queue.main.async do
          Bacon.handle_specification_end(error_message || '')
          if delegate.respond_to?('bacon_specification_did_finish:')
            delegate.bacon_specification_did_finish(self)
            #delegate.performSelectorOnMainThread('bacon_specification_did_finish:', withObject:self, waitUntilDone:true)
          end
        end
        # Never kill the runloop of the main thread!
        unless Dispatch::Queue.current.to_s == Dispatch::Queue.main.to_s
          CFRunLoopStop(CFRunLoopGetCurrent())
        end
      end
    end

    # TODO does not actually continue the spec execution...
    def timedout!
      puts "TIMED OUT: #{full_name}"
      @exception = Error.new(:error, "timed out: #{full_name}")
      @finished = true
      if Dispatch::Queue.current.to_s == Dispatch::Queue.main.to_s
        puts "OH NOES, TRYING TO KILL THE RUNLOOP OF THE MAIN THREAD!"
      end
      #Bacon.dispatch_on_main_thread do
      Dispatch::Queue.main.async do
        Bacon.handle_specification_end(error_message || '')
        if delegate.respond_to?('bacon_specification_did_finish:')
          delegate.bacon_specification_did_finish(self)
          #delegate.performSelectorOnMainThread('bacon_specification_did_finish:', withObject:self, waitUntilDone:true)
        end
      end
      CFRunLoopStop(CFRunLoopGetCurrent())
    end

    def full_name
      "#{@context.class.name} #{@description}"
    end

    def finished?
      @finished
    end

    def passed?
      @exception.nil?
    end

    def bacon_error?
      @exception.kind_of?(Error)
    end

    def failure?
      @exception.count_as_failure? if bacon_error?
    end

    def error?
      !@exception.nil? && !failure?
    end

    def pending?
      error_message == 'MISSING'
    end

    def error_message
      if bacon_error?
        @exception.count_as.to_s.upcase
      elsif @exception
        "ERROR: #{@exception.class}"
      end
    end

    def filtered_backtrace
      $DEBUG ? @exception.backtrace : @exception.backtrace.find_all { |line| line !~ /bin\/macbacon|\/mac_bacon\.rb:\d+/ }
    end

    def error_log
      if @exception
        log = ''
        log << "#{@exception.class}: #{@exception.message}\n"
        filtered_backtrace.each_with_index { |line, i|
          log << "\t#{line}#{i==0 ? ": #{@context.class.name} - #{@description}" : ""}\n"
        }
        log
      end
    end
  end # Specification
end
