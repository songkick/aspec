module Aspec
  class Parser
    def initialize(source)
      @lines = source.split("\n").map {|l| l.strip}
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
            tests.last << parse_line(line, line_num)
          end
        end
        tests.select {|tests| tests.any?}.map {|steps| Test.new(steps) }
      end
    end

    def parse_line(line, line_num)
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

  end
end
