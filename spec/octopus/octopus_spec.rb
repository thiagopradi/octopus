require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Octopus do
  it "should load the shards.yml file to start working" do
    Octopus.config().should be_kind_of(Hash)
  end
end
