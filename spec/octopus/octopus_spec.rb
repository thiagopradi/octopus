require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Octopus do
  describe "#config method" do
    it "should load shards.yml file to start working" do
      Octopus.config().should be_kind_of(Hash)
    end
  end

  describe "#directory method" do
    it "should return the directory that contains the shards.yml file" do
      Octopus.directory().should == File.expand_path(File.dirname(__FILE__) + "/../")
    end
  end
end
