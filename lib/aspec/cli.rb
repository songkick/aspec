
module Aspec
  class CLI
    def initialize(args)
      bits = args[0].split(":")
      paths = bits.select {|b| File.exist?(b) }
      aspec_dir = File.dirname(paths.first)
      load File.expand_path(aspec_dir + "/aspec_helper.rb")
      @file = bits[0]
      @lines = bits[1..-1].map(&:to_i)
      @verbose = args.include?("-v")
      @slow = args.include?("--slow")
      @formatter = args.include?("--junit") ? Formatter::JUnit.new(@file) : Formatter::Terminal.new(@verbose)
    end

    def run
      TestRunner.new(@file, :verbose => @verbose,
                            :slow => @slow,
                            :formatter => @formatter).run(@lines)
    end
  end
end
