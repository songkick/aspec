
module Aspec
  class Test
    include Rack::Test::Methods

    def initialize(steps)
      @steps = steps
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

    def app
      @app
    end

    def run(config)
      formatter  = config.formatter
      is_slow    = config.slow?
      @app       = config.get_app_under_test.call
      #Time.at(0) causes our token to never expire
      start_time = Time.now
      failed = false

      @steps.each_with_index do |step, time_delta|
        if is_slow
          sleep 0.5
        end

        if ARGV.include?("--debug")
          formatter.debug(step)
        end

        if failed
          formatter.step_error_title(step)
          next
        end

        if step[:comment]
          formatter.comment(step[:comment])
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
              header "AUTHORIZATION", "Bearer #{config.auth_token}"
              send(step[:method].downcase, step[:url])
            end
          rescue Object => e
            formatter.exception("  " + e.class.to_s + ": " + e.message)
            e.backtrace.each do |backtrace_line|
              formatter.exception("  " + backtrace_line) unless backtrace_line =~ /vendor\/bundle/ or backtrace_line =~ /test.rb/
            end
            failed = true
          end

          unless failed or step[:method][0] == ">"
            if last_response.status.to_s != step[:exp_status]
              formatter.exception(" * Expected status #{step[:exp_status]} got #{last_response.status}")
              failed = true
            end

            if step[:exp_content_type] == "application/json" && !step[:resp_is_regex]
              begin
                expected_object = JSON.parse(step[:exp_response])
                begin
                  response_object = JSON.parse(last_response.body)
                  if expected_object != response_object
                    formatter.exception(" * Expected response #{JSON.pretty_generate(expected_object)} got #{JSON.pretty_generate(response_object)}")
                    failed = true
                  end
                rescue JSON::ParserError
                  formatter.exception(" * Response did not parse correctly as JSON: #{last_response.body.inspect}")
                  failed = true
                end
              rescue JSON::ParserError
                formatter.exception(" * Expectation did not parse correctly as JSON: #{step[:exp_response].inspect}")
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
                  formatter.exception(" * Expected response pattern #{step[:exp_response].inspect} didn't match #{last_response.body.inspect}")
                  failed = true
                end
              elsif !step[:resp_is_regex] & (last_response.body.to_s != step[:exp_response])
                formatter.exception(" * Expected response #{step[:exp_response].inspect} got #{last_response.body.inspect[0..50] + "..."}")
                failed = true
              end
            end

            if step[:exp_content_type]
              exp_content_type_header = "#{step[:exp_content_type]}"
              exp_content_type_header << ";charset=utf-8" unless exp_content_type_header.start_with? "image/"
              if last_response.headers["Content-Type"].gsub(/\s+/, "") != exp_content_type_header
                formatter.exception(" * Expected content type #{exp_content_type_header} got #{last_response.headers["Content-Type"]}")
                failed = true
              end
            end
          end

          if failed
            formatter.step_error(step)
          else
            formatter.step_pass(step)
          end
        end
      end
      !failed
    end
  end
end



