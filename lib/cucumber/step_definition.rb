require 'cucumber/core_ext/string'
require 'cucumber/core_ext/proc'

module Cucumber
  # A Step Definition holds a Regexp and a Proc, and is created
  # by calling <tt>Given</tt>, <tt>When</tt> or <tt>Then</tt>
  # in the <tt>step_definitions</tt> ruby files - for example:
  #
  #   Given /I have (\d+) cucumbers in my belly/ do
  #     # some code here
  #   end
  #
  class StepDefinition
    class MissingProc < StandardError
      def message
        "Step definitions must always have a proc"
      end
    end

    attr_reader :regexp

    def initialize(regexp, &proc)
      raise MissingProc if proc.nil?
      @regexp, @proc = regexp, proc
      @proc.extend(CoreExt::CallIn)
    end

    #:stopdoc:

    def match(step_name)
      case step_name
      when String then @regexp.match(step_name)
      when Regexp then @regexp == step_name
      end
    end

    def format_args(step_name, format)
      step_name.gzub(@regexp, format)
    end

    def matched_args(step_name)
      step_name.match(@regexp).captures
    end

    def execute(world, *args)
      begin
        args = args.map{|arg| Ast::PyString === arg ? arg.to_s : arg}
        world.instance_exec(*args, &@proc)
      rescue Exception => e
        method_line = "#{__FILE__}:#{__LINE__ - 2}:in `execute'"
        e.cucumber_strip_backtrace!(method_line, @regexp.to_s)
        raise e
      end
    end

    def to_backtrace_line
      "#{file_colon_line}:in `#{@regexp.inspect}'"
    end

    def file_colon_line
      @proc.file_colon_line
    end
  end
end
