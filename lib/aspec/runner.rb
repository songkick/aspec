
module Aspec
  class TestRunner

    class Test
      include Rack::Test::Methods

      def initialize(steps, options={})
        @steps = steps
        @verbose = options[:verbose]
        @slow = options[:slow]
        @formatter = options[:formatter]
      end

      def verbose?
        @verbose
      end

      def slow?
        @slow
      end

      def app
        Aspec.configuration.get_app_under_test.call
      end

      def validate_method(method)
        raise "unknown method #{method}" unless %W(GET POST DELETE PUT).include?(method)
      end

      def comment_only?
        @steps.all? {|s| s[:comment]}
      end

      def contains_line?(line_num)
        @steps.first[:line_num] <= line_num and @steps.last[:line_num] >= line_num
      end

      def run
        start_time = Time.at(0)
        failed = false
        @steps.each_with_index do |step, time_delta|
          if slow?
            sleep 0.5
          end

          if ARGV.include?("--debug")
            @formatter.debug(step)
          end
          if failed
            @formatter.step_error_title(step)
            next
          end

          if step[:comment]
            @formatter.comment(step[:comment])
          else
            Time.stub!(:now).and_return(start_time + 2*time_delta)
            begin
              if step[:method][0] == ">"
                method = step[:method][1..-1]
                validate_method(method)
                url = "http://" + step[:url]
                FakeWeb.register_uri(method.downcase.to_sym, url,
                    :body => step[:exp_response],
                    :content_type => step[:exp_content_type]
                  )
              else
                validate_method(step[:method])
                send(step[:method].downcase, step[:url])
              end
            rescue Object => e
              @formatter.exception("  " + e.class.to_s + ": " + e.message)
              e.backtrace.each do |backtrace_line|
                @formatter.exception("  " + backtrace_line) unless backtrace_line =~ /vendor\/bundle/ or backtrace_line =~ /test.rb/
              end
              failed = true
            end
            unless failed or step[:method][0] == ">"
              if last_response.status.to_s != step[:exp_status]
                @formatter.exception("Expected status #{step[:exp_status]} got #{last_response.status}")
                failed = true
              end
              if step[:exp_content_type] == "application/json" && !step[:resp_is_regex]
                begin
                  expected_object = JSON.parse(step[:exp_response])

                  begin
                    response_object = JSON.parse(last_response.body)
                    if expected_object != response_object
                      @formatter.exception("Expected response #{JSON.pretty_generate(expected_object)} got #{JSON.pretty_generate(response_object)}")
                      failed = true
                    end
                  rescue JSON::ParserError
                    @formatter.exception("Response did not parse correctly as JSON: #{last_response.body.inspect}")
                    failed = true
                  end
                rescue JSON::ParserError
                  @formatter.exception("Expectation did not parse correctly as JSON: #{step[:exp_response].inspect}")
                  failed = true
                end
              else
                if step[:resp_is_regex]
                  pattern = nil, body = nil
                  if !(step[:exp_content_type].start_with? 'text/')
                    pattern = Regexp.new(step[:exp_response].force_encoding("ASCII-8BIT"), Regexp::FIXEDENCODING)
                    body = last_response.body.to_s.force_encoding("ASCII-8BIT")
                  else
                    pattern = Regexp.new(step[:exp_response])
                    body = last_response.body.to_s
                  end
                  if !(body =~ pattern)
                    @formatter.exception("Expected response pattern #{step[:exp_response].inspect} didn't match #{last_response.body.inspect}")
                    failed = true
                  end
                elsif !step[:resp_is_regex] & (last_response.body.to_s != step[:exp_response])
                  @formatter.exception("Expected response #{step[:exp_response].inspect} got #{last_response.body.inspect}")
                  failed = true
                end
              end
              if step[:exp_content_type]
                exp_content_type_header = "#{step[:exp_content_type]}"
                exp_content_type_header << ";charset=utf-8" unless exp_content_type_header.start_with? "image/"
                if last_response.headers["Content-Type"] != exp_content_type_header
                  @formatter.exception("Expected content type #{exp_content_type_header} got #{last_response.headers["Content-Type"]}")
                  failed = true
                end
              end
            end

            if failed
              @formatter.step_error(step)
            else
              @formatter.step_pass(step)
            end
          end
        end
        !failed
      end

    end

    def initialize(path, options = {})
      @lines = File.readlines(path).map {|l| l.strip}
      @options = options
    end

    def formatter
      @options[:formatter]
    end

    def verbose?
      @options[:verbose]
    end

    def slow?
      @options[:slow]
    end

    def before_each
      if before_block = Aspec.configuration.get_before
        before_block.call
      end
    end

    def parse(line, line_num)
      if line =~ /^\s*(#.*)$/
        {:comment => $1, :line_num => line_num}
      else
        bits = line.split(" ")
        method = bits[0]
        url    = bits[1]
        url    = URI.encode(url)

        exp_status = bits[2]
        exp_status = exp_status.strip if exp_status
        exp_content_type = bits[3]
        exp_content_type = exp_content_type.strip if exp_content_type
        exp_response = (bits[4..-1]||[]).join(" ")
        is_regex = exp_response[0] == '/' and exp_response[-1] == '/' and exp_response.size > 2
        exp_response = exp_response[1 .. -2] if is_regex

        {:method => method, :url => url,
          :exp_status => exp_status, :exp_content_type => exp_content_type, :exp_response => exp_response,
          :resp_is_regex => is_regex, :line_num => line_num
        }
      end
    end

    def tests
      @tests ||= begin
        tests = [[]]
        @lines.each_with_index do |line, line_num|
          if line =~ /^\s*$/
            if tests.last.length > 0
              tests << []
            end
          elsif line =~ /^\s*\\(.*)$/
            tests.last.last[:exp_response] = (tests.last.last[:exp_response] + $1)
          else
            tests.last << parse(line, line_num)
          end
        end
        tests.select {|tests| tests.any?}.map {|steps| Test.new(steps, :verbose => verbose?, :slow => slow?, :formatter => formatter) }
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

