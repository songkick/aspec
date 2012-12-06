
module Aspec
  module Formatter
    class JUnit
      def initialize(test_file_name, verbose = false, out_file_name = '.junit_api_spec_runner_specs')
        @test_results = { :failures => [], :successes => [] }
        @out = File.open(out_file_name, 'w')
        @test_file_name = test_file_name
        @exceptions = []
        at_exit do
          unless @out.closed?
            @out.flush
            @out.close
          end
        end
      end

      def clear
      end

      def comment(comment_string)
      end

      def step_error(step)
        @test_results[:failures] << [step_line(step), @exceptions]
        @exceptions = []
      end

      def exception(error_string)
        @exceptions << error_string
      end

      def step_error_title(step)
      end

      def step_pass(step)
        @test_results[:successes] << step_line(step)
      end

      def debug
      end

      def dump_summary(summary)
        @out.puts("<?xml version=\"1.0\" encoding=\"utf-8\" ?>")
        @out.puts("<testsuite errors=\"0\" failures=\"#{failure_count}\" tests=\"#{example_count}\" time=\"#{duration=0}\" timestamp=\"#{Time.now.iso8601}\">")
        @out.puts("  <properties />")

        @test_results[:successes].each do |success_string|
          #TODO: Add timings
          runtime = 0
          @out.puts("  <testcase classname=\"#{@test_file_name}\" name=\"#{test_name(success_string)}\" time=\"#{runtime}\" />")
        end
        @test_results[:failures].each do |(failure_string, exceptions)|
          runtime = 0
          @out.puts("  <testcase classname=\"#{@test_file_name}\" name=\"#{failure_string}\" time=\"#{runtime}\">")

          @out.puts("    <failure message=\"failure\" type=\"failure\">")
          @out.puts("<![CDATA[ #{exceptions} ]]>")
          @out.puts("    </failure>")
          @out.puts("  </testcase>")
        end
        @out.puts("</testsuite>")
      end

      private
      def step_line(step)
        "#{step[:method]} #{step[:url]} line: #{step[:line_num]}"
      end

      def test_name(string)
        xml_encode(string.split("\n")[0].strip)
      end

      def example_count
        @test_results[:successes].count + failure_count
      end

      def failure_count
        @test_results[:failures].count
      end

      def xml_encode(string)
        #TODO: Use builder to do this
        string.gsub!('&', '&amp;')
        string.gsub!('>', '')
        string.gsub!('"','&quot;')
        string
      end
    end
  end
end
