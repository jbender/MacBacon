require_relative "shared"
require_relative "helpers"
require_relative "specification"

module Bacon
  class Context
    include Helpers

    attr_reader :specification

    def initialize(specification)
      @specification = specification
    end

    def raise?(*args, &block)
      block.raise?(*args)
    end

    def throw?(*args, &block)
      block.throw?(*args)
    end

    def change?(*args, &block)
      block.change?(*args)
    end

    def should(*args, &block)
      if self.class.context_depth == 0
        it('should '+args.first,&block)
      else
        super(*args,&block)
      end
    end

    def describe(*args, &block)
      self.class.describe(*args, &block)
    end

    # If no explicit time to wait is given, then execution can be resumed by
    # calling the #resume method or until the Context#timeout has been reached.
    def wait(seconds = nil)
      if seconds
        CFRunLoopRunInMode(KCFRunLoopDefaultMode, seconds, false)
      else
        @postpone_execution = true
        CFRunLoopRunInMode(KCFRunLoopDefaultMode, 0.001, false) while @postpone_execution
      end
      yield if block_given?
    end

    def resume
      @postpone_execution = false
    end

    def wait_for_change(object_to_observe, key_path, &block)
      object_to_observe.addObserver(self, forKeyPath:key_path, options:0, context:nil)
      wait(&block)
    end

    def observeValueForKeyPath(key_path, ofObject:object, change:_, context:__)
      resume
    end

    class << self
      attr_reader :name, :block, :context_depth, :specifications, :defined_in
      attr_accessor :run_on_main_thread, :timeout

      def init_context(name, context_depth, before = nil, after = nil, &block)
        # find the first file in the backtrace which is not this file
        if defined_in = caller.find { |line| line[0,__FILE__.size] != __FILE__ }
          defined_in = File.expand_path(defined_in.match(/^(.+?):\d+/)[1])
        else
          puts "[!] Unable to determine the file in which the context is defined."
        end

        context = Class.new(self) do
          @name = name
          @before, @after = (before ? before.dup : []), (after ? after.dup : [])
          @block = block
          @specifications = []
          @context_depth = context_depth
          @timeout = 10 # seconds
          @defined_in = defined_in
        end
        Bacon.contexts << context
        context.class_eval(&block)
        context
      end

      def run_on_main_thread?
        @run_on_main_thread || !Bacon.concurrent?
      end

      def before(&block)
        @before << block
      end

      def after(&block)
        @after << block
      end

      def behaves_like(*names)
        names.each { |name| class_eval(&Shared[name]) }
      end

      def it(description, &block)
        return unless "#{@name} #{description}" =~ Bacon.restrict_name
        block ||= lambda { should.flunk "not implemented" }
        spec = Specification.new(self, description, block, @before, @after)
        @specifications << spec
        spec
      end

      def describe(*args, &block)
        args.unshift(name)
        init_context(args.join(' '), @context_depth + 1, @before, @after, &block)
      end
      # alias_method :context, :describe
      def context(*args, &block)
        describe(*args, block)
      end
    end
  end
end
