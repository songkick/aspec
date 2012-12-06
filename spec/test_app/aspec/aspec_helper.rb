$:.push(File.expand_path("../../", __FILE__))
require 'test_app'

Aspec.configure do |c|
  c.app_under_test do
    TestApp.new
  end
end
