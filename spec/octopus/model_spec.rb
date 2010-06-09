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

    it "should allow scoping dynamically" do
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
    
    describe "passing a block" do
      it "should allow queries be executed inside the block, ponting to a specific shard" do
         User.using(:canada) do
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
    
    describe "when you have a relationship" do
      it "should find all models in the specified shard" do
        brazil_client = Client.using(:brazil).create!(:name => "Brazil Client")
        master_client = Client.create!(:name => "Master Client")
        
        item_brazil = Item.using(:brazil).create!(:name => "Brazil Item", :client => brazil_client)
        item_master = Item.create!(:name => "Master Item", :client => master_client)
        Client.using(:brazil).find_by_name("Brazil Client").items.should == [item_brazil]
      end
    end
    
    describe "raising errors" do
      it "should raise a error when you specify a shard that doesn't exist" do
        lambda { User.using(:crazy_shard) }.should raise_error("Nonexistent Shard Name: crazy_shard")
      end
    end
  end

  describe "using a postgresql shard" do
    after(:each) do
      User.using(:postgresql_shard).delete_all
    end
    
    it "should update the Arel Engine" do
      User.using(:postgresql_shard).arel_engine.connection.adapter_name.should == "PostgreSQL"
      User.using(:alone_shard).arel_engine.connection.adapter_name.should == "MySQL"
    end
    
    it "should works with writes and reads" do
      pending()
      #u = User.using(:postgresql_shard).create!(:name => "PostgreSQL User")
      #       #User.using(:postgresql_shard).arel_table.columns.should == ""
      #       User.using(:postgresql_shard).scoped.should ==  ""
      #       User.using(:alone_shard).find(:all).should == []
    end
  end
  
  describe "#replicated_model method" do
    before(:each) do
      Octopus.stub!(:env).and_return("production_replicated")
      @proxy = Octopus::Proxy.new(Octopus.config())
      #TODO - This is ugly, but is better than mocking
      ActiveRecord::Base.class_eval("@@connection_proxy = nil")
      #TODO - This is ugly, but is better than mocking
    end
    
    after(:each) do
      #TODO - One little Kitten dies each time this code is executed.
      ActiveRecord::Base.class_eval("@@connection_proxy = nil")
    end
    
    it "should be replicated" do
      ActiveRecord::Base.connection_proxy.replicated.should be_true
    end
    
    it "should mark the Cat model as replicated" do
      Cat.all.should == []
      ActiveRecord::Base.connection_proxy.replicated_models.first.should == "Cat"
    end
  end
  
  describe "#sharded_by method" do
    it "should send all queries to the specify shard" do
      pending()
    end
  end
end