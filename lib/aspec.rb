require 'rubygems'

require 'rack/test'
require 'rspec/mocks/standalone'
require 'term/ansicolor'
require 'json'

require 'aspec/cli'
require 'aspec/formatters/terminal'
require 'aspec/formatters/junit'
require 'aspec/runner'
require 'aspec/parser'
require 'aspec/test'

module Aspec
  def self.configuration
    @configuration ||= Configure.new
  end

  def self.configure
    yield configuration
  end

  class Configure
    attr_accessor :verbose, :slow, :formatter, :auth_token

    def verbose?; verbose; end
    def slow?; slow; end

    def app_under_test(&block)
      @app_under_test = block
    end

    def before(&block)
      @before = block
    end

    def get_app_under_test
      @app_under_test
    end

    def get_before
      @before
    end

    def after_suite(&block)
      @after_suite = block
    end

    def get_after_suite
      @after_suite
    end
  end
end

