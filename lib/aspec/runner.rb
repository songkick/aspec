
module Aspec
  class TestRunner

    def initialize(path, options = {})
      @source = File.read(path)
      @options = options
    end

    def parser
      @parser ||= Parser.new(@source)
    end

    def verbose?
      Aspec.configuration.verbose?
    end

    def slow?
      Aspec.configuration.slow?
    end

    def formatter
      Aspec.configuration.formatter
    end

    def tests
      parser.tests
    end

    def before_each
      if before_block = Aspec.configuration.get_before
        before_block.call
      end
    end

    def run(lines)
      successes = 0
      failures = 0
      if lines.any?
        run_tests = tests.select {|test| lines.any? {|line_num| test.contains_line?(line_num)}}
      else
        run_tests = tests
      end
      run_tests.each do |test|
        before_each
        if test.run
          successes += 1 unless test.comment_only?
          puts if verbose?
        else
          failures += 1
          puts
        end
        formatter.clear
      end
      formatter.dump_summary "#{successes} passed, #{failures} failed.".send(failures > 0 ? :red : :green)
      if after_suite_block = Aspec.configuration.get_after_suite
        after_suite_block.call
      end
      if failures > 0
        exit(1)
      else
        exit(0)
      end
    end
  end
end

