# Bacon -- small RSpec clone.
#
# "Truth will sooner come out from error than from confusion." ---Francis Bacon

# Copyright (C) 2007, 2008 Christian Neukirchen <purl.org/net/chneukirchen>
#
# Bacon is freely distributable under the terms of an MIT-style license.
# See COPYING or http://www.opensource.org/licenses/mit-license.php.

framework "Cocoa"

# Monkeypatch relative require statements
unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

require "mac_bacon/version"
require "mac_bacon/helpers"
require "mac_bacon/spec_dox_output"
require "mac_bacon/test_unit_output"
require "mac_bacon/counter"
require "mac_bacon/error"
require "mac_bacon/context"
require "mac_bacon/specification"
require "mac_bacon/should"

require "monkeypatches/object"
require "monkeypatches/true_class"
require "monkeypatches/false_class"
require "monkeypatches/proc"
require "monkeypatches/numeric"
require "monkeypatches/kernel"

# We need to use Kernel::print when printing which specification is being run.
# But we want to know this as soon as possible, hence we need to sync.
$stdout.sync = true

module Bacon
  class << self
    extend SpecDoxOutput

    attr_accessor :restrict_name

    attr_accessor :backtraces

    # This can be used by a `client' to receive status updates:
    # * When a spec will start running: bacon_specification_will_start(spec)
    # * When a spec has finished running: bacon_specification_did_finish(spec)
    # * When Bacon has finished a spec run.
    attr_accessor :delegate

    attr_accessor :concurrent
    alias_method  :concurrent?, :concurrent

    def clear
      @contexts = @specifications = @requirements = nil
    end

    def contexts
      @contexts ||= []
    end

    def specifications
      @specifications ||= []
    end

    def requirements
      @requirements ||= []
    end

    # IMPORTANT!
    #
    # Make sure to never call this method directly from the main GCD queue.
    # Instead do something like:
    #
    #   Bacon.performSelector('run', withObject:nil, afterDelay:0)
    def run
      @timer ||= Time.now
      self.performSelector(concurrent? ? "run_all_specs_concurrent" : "run_all_specs_serial", withObject:nil, afterDelay:0)
      NSApplication.sharedApplication.run
    end

    def run_all_specs_serial
      contexts.each do |context|
        context.specifications.each do |spec|
          begin
            spec.run
          rescue Object => e
            puts "An error bubbled up, this should really not happen! The error was: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
            raise e
          end
        end
      end
      bacon_did_finish
    end

    def run_all_specs_concurrent
      main_queue       = Dispatch::Queue.main
      concurrent_queue = Dispatch::Queue.concurrent
      group            = Dispatch::Group.new
      contexts.each do |context|
        queue = context.run_on_main_thread? ? main_queue : concurrent_queue
        context.specifications.each do |spec|
          queue.async(group) do
            begin
              spec.performSelector('run', withObject:nil, afterDelay:0)
              CFRunLoopRun() unless context.run_on_main_thread? # Should already have a running runloop!
            rescue Object => e
              puts "An error bubbled up on a GCD thread, this should really not happen! The error was: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
            end
          end
        end
      end
      # TODO bug in MacRuby which thinks that the main queue is not a Queue object
      #group.notify(main_queue) do
      group.notify(concurrent_queue) do
        #self.performSelectorOnMainThread('bacon_did_finish', withObject:nil, waitUntilDone:true)
        Dispatch::Queue.main.async do
          bacon_did_finish
        end
        # TODO MacRuby bug, leads to segfault
        #Bacon.dispatch_on_main_thread { bacon_did_finish }
      end
    end

    def dispatch_on_main_thread(&block)
      # TODO MacRuby bug/feature, can't compare two Queue objects directly, have to use their names
      if Dispatch::Queue.current.to_s == Dispatch::Queue.main.to_s
        block.call
      else
        Dispatch::Queue.main.sync(&block)
      end
    end

    private

    def bacon_did_finish
      if delegate.respond_to?('bacon_did_finish')
        delegate.bacon_did_finish
      end
      handle_summary
      exit Counter.not_passed
    end
  end

  self.restrict_name = //
  self.backtraces    = true
  self.concurrent    = false
end
