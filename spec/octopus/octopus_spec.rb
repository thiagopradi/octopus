require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Octopus" do
  describe "the API" do
    it "should load the shards.yml file to start working" do
      Octopus.config().should == {"test"=>{"shards"=>{"canada"=>{"adapter"=>"sqlite3", "database"=>"/Users/tchandy/Projetos/octopus/spec/db/canada.db"}}}}
    end
    
    it "should support replicated databases" do
      pending
    end
    
    it "should support selecting the shards on controller" do
      pending
    end
    
    it "should allow running code inside blocks " do
      pending
    end
    
    it "should support selecting the shard in a before_filter on controller" do
      pending
    end
    
    it "should allow selecting the shards on scope" do
      pending
    end
  end
end
