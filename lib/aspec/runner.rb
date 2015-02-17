
module Aspec
  class TestRunner
    include Term::ANSIColor

    attr_reader :config, :source

    def initialize(config, paths)
      @paths = paths
      @config = config
    end

    def verbose?
      config.verbose?
    end

    def slow?
      config.slow?
    end

    def formatter
      config.formatter
    end

    def tests
      @tests ||= begin
        result = []
        @paths.each do |path|
          parser = Parser.new(File.read(path))
          result += parser.tests
        end
        result.flatten
      end
    end

    def before_each
      if before_block = config.get_before
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
        if test.run(config)
          successes += 1 unless test.comment_only?
          puts if verbose?
        else
          failures += 1
          puts
        end
        formatter.clear
      end
      color = send(failures > 0 ? :red : :green)
      formatter.dump_summary color + "#{successes} passed, #{failures} failed." + reset

      if after_suite_block = config.get_after_suite
        after_suite_block.call
      end

      failures
    end
  end
end

