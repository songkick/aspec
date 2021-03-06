require 'spec_helper'

describe Aspec::CLI do
  def test_app_dir
    File.expand_path("../test_app", __FILE__)
  end

  it "should list all files in a directory" do
    cli = Aspec::CLI.new(test_app_dir, ["aspec/"])
    expected_results = [
      File.expand_path("aspec/failing.aspec", test_app_dir),
      File.expand_path("aspec/passing.aspec", test_app_dir)].sort

    expect(cli.aspec_files.sort).to eq expected_results
  end

  it "should fail for failing specs" do
    cli = Aspec::CLI.new(test_app_dir, ["aspec/failing.aspec"])

    expect(cli.run).to eq 1
  end

  it "should pass for passing specs" do
    cli = Aspec::CLI.new(test_app_dir, ["aspec/passing.aspec"])

    expect(cli.run).to eq 0
  end
end
