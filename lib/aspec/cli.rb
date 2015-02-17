require 'pathname'

module Aspec
  class CLI
    attr_reader :args, :working_dir

    def initialize(working_dir, args)
      @working_dir = Pathname.new(working_dir)
      @args = args
    end

    def aspec_files
      files = []
      @args.each do |arg|
        arg = File.expand_path(arg, working_dir)
        if File.exist?(arg)
          if File.directory?(arg)
            files += Dir[arg + "**/*.aspec"]
          elsif arg =~ /.*\.aspec/
            files << arg
          end
        end
      end
      files
    end

    def aspec_helper_path
      working_dir.join("aspec/aspec_helper.rb")
    end

    def run
      bits = args[0].split(":")

      load aspec_helper_path if File.exist?(aspec_helper_path)

      @lines = bits[1..-1].map(&:to_i)
      is_verbose = args.include?("-v")
      Aspec.configure do |c|
        c.verbose   = is_verbose
        c.slow      = args.include?("--slow")
        c.formatter = args.include?("--junit") ? Formatter::JUnit.new(@file) : Formatter::Terminal.new(is_verbose)
      end
      TestRunner.new(Aspec.configuration, aspec_files).run(@lines)
    end
  end
end
