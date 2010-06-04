require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Octopus::Model do
  describe "#using method" do
    it "should return self after calling the #using method" do
      User.using(:canada).should == User
    end

    it "should allow selecting the shards on scope" do
      User.using(:canada).create!(:name => 'oi')
      User.using(:canada).count.should == 1
      User.using(:master).count.should == 0
    end

    it "should allow scoping dinamically" do
      User.using(:canada).using(:master).using(:canada).create!(:name => 'oi')
      User.using(:canada).using(:master).count.should == 0
      User.using(:master).using(:canada).count.should == 1
    end

    it "should clean the current_shard after executing the current query" do
      User.using(:canada).create!(:name => "oi")
      User.count.should == 0 
    end

    it "should support both groups and alone shards" do
      User.using(:alone_shard).create!(:name => "Alone")
      User.using(:alone_shard).count.should == 1
      User.using(:master).count.should == 0
      User.using(:canada).count.should == 0
      User.using(:brazil).count.should == 0
    end
    
    it "should raise a error when you specify a shard that doesn't exist" do
      lambda { User.using(:crazy_shard) }.should raise_error("Nonexistent Shard Name")
    end
  end

  describe "#using_shard method" do
    it "should allow passing a block to #using" do
      User.using_shard(:canada) do
        User.create(:name => "oi")
      end

      User.using(:canada).count.should == 1
      User.using(:master).count.should == 0
      User.count.should == 0      
    end

    it "should allow execute queries inside a model" do
      u = User.new
      u.awesome_queries()
      User.using(:canada).count.should == 1
      User.count.should == 0
    end
  end
  
  describe "#sharded_by method" do
    it "should send all queries to the specify shard" do
      pending()
    end
  end
end