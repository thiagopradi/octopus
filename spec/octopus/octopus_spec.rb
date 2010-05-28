require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Octopus" do
  describe "the API" do    
    it "should load the shards.yml file to start working" do
      Octopus.config().should be_kind_of(Hash)
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
      User.using(:canada).create!(:name => 'oi')
      User.using(:canada).count.should == 1
      User.using(:master).count.should == 0
      #clear the database that isn't cleared by DatabaseCleaner
      User.using(:canada).delete_all()
    end
    
    it "should allow scoping dinamically" do
      User.using(:canada).using(:master).using(:canada).create!(:name => 'oi')
      User.using(:canada).using(:master).count.should == 0
      User.using(:master).using(:canada).count.should == 1
      #clear the database that isn't cleared by DatabaseCleaner
      User.using(:canada).delete_all()      
    end
  end
end
