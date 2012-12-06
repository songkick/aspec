
module Aspec
  class CLI
    def initialize(args)
      bits = args[0].split(":")
      paths = bits.select {|b| File.exist?(b) }
      aspec_dir = File.dirname(paths.first)
      load File.expand_path(aspec_dir + "/aspec_helper.rb")
      @file = bits[0]
      @lines = bits[1..-1].map(&:to_i)
      Aspec.configure do |c|
        c.verbose   = args.include?("-v")
        c.slow      = args.include?("--slow")
        c.formatter = args.include?("--junit") ? Formatter::JUnit.new(@file) : Formatter::Terminal.new(@verbose)
      end
    end

    def run
      TestRunner.new(Aspec.configuration, @file).run(@lines)
    end
  end
end
