require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Octopus::Model do
  describe "#using method" do
    it "should return self after calling the #using method" do
      User.using(:canada).should == User
    end

    it "should allow selecting the shards on scope" do
      User.using(:canada).create!(:name => 'oi')
      User.using(:canada).count.should == 1
      User.count.should == 0
    end
    
    it "should select the correct shard" do
      pending()
      # User.using(:canada)
      # User.create!(:name => 'oi')
      # User.count.should == 1
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
      u = User.using(:alone_shard).create!(:name => "Alone")
      User.using(:alone_shard).count.should == 1
      User.using(:canada).count.should == 0
      User.using(:brazil).count.should == 0
      User.count.should == 0
    end

    describe "#current_shard attribute" do
      it "should store the attribute when you create or find an object" do
        u = User.using(:alone_shard).create!(:name => "Alone")
        u.current_shard.should == :alone_shard
        User.using(:canada).create!(:name => 'oi')
        u = User.using(:canada).find_by_name("oi")
        u.current_shard.should == :canada      
      end

      it "should store the attribute when you find multiple instances" do
        5.times { User.using(:alone_shard).create!(:name => "Alone") }
        User.using(:alone_shard).all.each do |u|
          u.current_shard.should == :alone_shard
        end
      end

      it "should works when you find, and after that, alter that object" do
        alone_user = User.using(:alone_shard).create!(:name => "Alone")
        master_user = User.using(:master).create!(:name => "Master")
        alone_user.name = "teste"
        alone_user.save
        User.using(:master).find(:first).name.should == "Master"
        User.using(:alone_shard).find(:first).name.should == "teste"
      end

      it "should work for the reload method" do
        User.using(:alone_shard).create!(:name => "Alone")
        u = User.using(:alone_shard).where(:name => "Alone").first
        u.reload
        u.name.should == "Alone"
      end
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

    describe "raising errors" do
      it "should raise a error when you specify a shard that doesn't exist" do
        lambda { User.using(:crazy_shard) }.should raise_error("Nonexistent Shard Name: crazy_shard")
      end
    end
  end

  describe "using a postgresql shard" do
    it "should update the Arel Engine" do
      User.using(:postgresql_shard).arel_engine.connection.adapter_name.should == "PostgreSQL"
      User.using(:alone_shard).arel_engine.connection.adapter_name.should == "MySQL"
    end

    it "should works with writes and reads" do
      u = User.using(:postgresql_shard).create!(:name => "PostgreSQL User")      
      User.using(:postgresql_shard).all.should == [u]      
      User.using(:alone_shard).find(:all).should == []
    end
  end
  
  describe "AR basic methods" do
    it "increment" do
      u = User.using(:brazil).create!(:name => "Teste", :number => 10)
      u = User.using(:brazil).find_by_number(10)
      u.increment(:number)
      u.save()
      u = User.using(:brazil).find_by_number(11).should_not be_nil        
    end

    it "increment!" do
      u = User.using(:brazil).create!(:name => "Teste", :number => 10)
      u = User.using(:brazil).find_by_number(10)
      u.increment!(:number)
      u = User.using(:brazil).find_by_number(11).should_not be_nil
    end

    it "toggle" do
      u = User.using(:brazil).create!(:name => "Teste", :admin => false)
      u = User.using(:brazil).find_by_name('Teste')
      u.toggle(:admin)
      u.save()
      u = User.using(:brazil).find_by_name('Teste').admin.should be_true
    end

    it "toggle!" do
      u = User.using(:brazil).create!(:name => "Teste", :admin => false)
      u = User.using(:brazil).find_by_name('Teste')
      u.toggle!(:admin)
      u = User.using(:brazil).find_by_name('Teste').admin.should be_true
    end
    
    it "count" do
      u = User.using(:brazil).create!(:name => "User1")
      u2 = User.using(:brazil).create!(:name => "User2")
      u3 = User.using(:brazil).create!(:name => "User3")
      User.using(:brazil).where(:name => "User2").count.should == 1
    end
  end
  
  describe "#replicated_model method" do
    it "should be replicated" do
      using_enviroment :production_replicated do 
        ActiveRecord::Base.connection_proxy.instance_variable_get(:@replicated).should be_true
      end
    end

    it "should mark the Cat model as replicated" do
      using_enviroment :production_replicated do 
        User.read_inheritable_attribute(:replicated).should be_false
        Cat.read_inheritable_attribute(:replicated).should be_true
      end
    end
  end
end