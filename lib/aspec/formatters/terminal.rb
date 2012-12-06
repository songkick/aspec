
module Aspec
  module Formatter
    class Terminal
      include Term::ANSIColor

      def initialize(verbose, out = STDOUT)
        @out = out
        @verbose = verbose
        @line_buffer ||= []
      end

      def clear
        @line_buffer.clear
      end

      def comment(comment_string)
        line(comment_string)
      end

      def exception(error_string)
        line(error_string)
      end

      def step_error_title(step)
        step_line(step)
      end

      def step_error(step)
        line(red + step_line(step) + reset)
        print_error unless @verbose
      end

      def step_pass(step)
        line(green + step_line(step) + reset)
      end

      def debug(step)
        @out.puts(step.inspect)
      end

      def dump_summary(summary)
        @out.puts summary
      end

      private

      def step_line(step)
        bits = [step[:method].rjust(7, " "), step[:url].ljust(50, " "), step[:exp_status], (step[:exp_content_type]||"")]
        if step[:exp_content_type] == "application/json"
          begin
            json_string = JSON.parse(step[:exp_response]).to_json
            if json_string.length > 20
              json_string = "\n" + JSON.pretty_generate(JSON.parse(step[:exp_response])).split("\n").map {|l| "         \\ #{l}"}.join("\n")
            end
            bits << json_string
          rescue JSON::ParserError
            bits << step[:exp_response]
          end
        else
          bits << step[:exp_response]
        end
        bits.join("\t")
      end

      def line(line_string)
        @out.puts(line_string) if @verbose
        @line_buffer << line_string
      end

      def print_error
        @line_buffer.each do |line|
          @out.puts line
        end
        @line_buffer = []
      end

    end
  end
end
