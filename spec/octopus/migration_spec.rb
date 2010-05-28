require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Octopus::Migration do
  before(:each) do 
    #ActiveRecord::Migrator.up(File.dirname(__FILE__)  + "/../migrations", 1)
  end
  
  it "should run just in the master shard" do
    pending()
  end
  
  it "should run on specific shard" do
    pending()
  end
  
  it "should run on specifieds shards" do
    pending()
  end
  
  it "should run on slaves on replication" do
    pending()
  end
  
  it "should run in all shards, master or another shards" do
    pending()
  end
end

