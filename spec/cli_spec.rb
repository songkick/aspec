require 'spec_helper'

describe Aspec::CLI do
  def test_app_dir
    File.expand_path("../test_app", __FILE__)
  end

  it "should list all files in a directory" do
    cli = Aspec::CLI.new(test_app_dir, ["aspec/"])
    cli.aspec_files.sort.should == [
      File.expand_path("aspec/failing.aspec", test_app_dir), 
      File.expand_path("aspec/passing.aspec", test_app_dir)].sort
  end
end
