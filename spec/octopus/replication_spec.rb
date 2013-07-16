require "spec_helper"

describe "when the database is replicated" do
  it "should send all writes/reads queries to master when you have a non replicated model" do
    OctopusHelper.using_environment :production_replicated do
      u = User.create!(:name => "Replicated")
      User.count.should == 1
      User.find(u.id).should == u
    end
  end

  it "should send all writes queries to master" do
    OctopusHelper.using_environment :production_replicated do
      Cat.create!(:name => "Slave Cat")
      Cat.find_by_name("Slave Cat").should be_nil
      Client.create!(:name => "Slave Client")
      Client.find_by_name("Slave Client").should_not be_nil
    end
  end

  it "should allow to create multiple models on the master" do
    OctopusHelper.using_environment :production_replicated do
      Cat.create!([{:name => "Slave Cat 1"}, {:name => "Slave Cat 2"}])
      Cat.find_by_name("Slave Cat 1").should be_nil
      Cat.find_by_name("Slave Cat 2").should be_nil
    end
  end

  describe "When enabling the query cache" do
    before(:each) do
      @counter = ActiveRecord::QueryCounter.new
    end

    it "should do the queries with cache" do
      # TODO - Support Rails 3.0
      if Octopus.rails31? || Octopus.rails32?
        active_support_subscribed(@counter.to_proc, 'sql.active_record') do 
          OctopusHelper.using_environment :replicated_with_one_slave do
            begin
              ActiveRecord::Base.connection.enable_query_cache!

              cat1 = Cat.using(:master).create!(:name => "Slave Cat 1")
              cat2 = Cat.using(:master).create!(:name => "Slave Cat 1")
              Cat.using(:master).find(cat1.id).should eq(cat1)
              Cat.using(:master).find(cat1.id).should eq(cat1)
              Cat.using(:master).find(cat1.id).should eq(cat1)

              cat3 = Cat.using(:slave1).create!(:name => "Slave Cat 1")
              cat4 = Cat.using(:slave1).create!(:name => "Slave Cat 1")
              Cat.find(cat3.id).id.should eq(cat3.id)
              Cat.find(cat3.id).id.should eq(cat3.id)
              Cat.find(cat3.id).id.should eq(cat3.id)

              @counter.query_count.should eq(14)
            ensure
              ActiveRecord::Base.connection.disable_query_cache!
            end
          end
        end
      end
    end
  end

  it "should allow #using syntax to send queries to master" do
    Cat.create!(:name => "Master Cat")

    OctopusHelper.using_environment :production_fully_replicated do
      Cat.using(:master).find_by_name("Master Cat").should_not be_nil
    end
  end

  it "should send the count query to a slave" do
    OctopusHelper.using_environment :production_replicated do
      Cat.create!(:name => "Slave Cat")
      Cat.count.should == 0
    end
  end

  def active_support_subscribed(callback, *args, &block)
    subscriber = ActiveSupport::Notifications.subscribe(*args, &callback)
    yield
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end
end


describe "when the database is replicated and the entire application is replicated" do
  before(:each) do
    Octopus.stub!(:env).and_return("production_fully_replicated")
    OctopusHelper.clean_connection_proxy()
  end

  it "should send all writes queries to master" do
    OctopusHelper.using_environment :production_fully_replicated do
      Cat.create!(:name => "Slave Cat")
      Cat.find_by_name("Slave Cat").should be_nil
      Client.create!(:name => "Slave Client")
      Client.find_by_name("Slave Client").should be_nil
    end
  end

  it "should send all writes queries to master" do
    OctopusHelper.using_environment :production_fully_replicated do
      Cat.create!(:name => "Slave Cat")
      Cat.find_by_name("Slave Cat").should be_nil
      Client.create!(:name => "Slave Client")
      Client.find_by_name("Slave Client").should be_nil
    end
  end

  it "should work with validate_uniquess_of" do
    Keyboard.create!(:name => "thiago")

    OctopusHelper.using_environment :production_fully_replicated do
      k = Keyboard.new(:name => "thiago")
      k.save.should be_false
      k.errors.full_messages.should == ["Name has already been taken"]
    end
  end

  it "should reset current shard if slave throws an exception" do
    OctopusHelper.using_environment :production_fully_replicated do
      Cat.create!(:name => "Slave Cat")
      Cat.connection.current_shard.should eql(:master)
      begin
        Cat.find(:all, :conditions => 'rubbish = true')
      rescue
      end
      Cat.connection.current_shard.should eql(:master)
    end
  end
end

