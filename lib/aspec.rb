

class Aspec
  def self.configuration
    @configuration ||= Configure.new
  end

  def self.configure
    yield configuration
  end

  class Configure
    def initialize
    end

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

