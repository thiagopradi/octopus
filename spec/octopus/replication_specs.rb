require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "when the database is replicated" do
  before(:each) do
    Octopus.stub!(:env).and_return("production_replicated")
    clean_connection_proxy()
  end

  it "should send all writes/reads queries to master when you have a non replicated model" do
    u = User.create!(:name => "Replicated")
    User.count.should == 1
    User.find(u.id).should == u
  end
  
  it "should send all writes queries to master" do
    u = Cat.using(:slave4).create!(:name => "Slave Cat")    
    u1 = Cat.using(:slave4).first
    u1.name = "Miau"
    u1.save()
    Cat.using(:slave4).first.name.should == "Slave Cat"
  end
  
  it "should allow to send some queries to a selected slave" do
    Cat.using(:slave4).create!([{:name => "Slave Cat 1"}, {:name => "Slave Cat 2"}])  
    Cat.using(:slave4).count.should == 2
  end

  it "should send read queries to slaves, when you have a replicated model, using a round robin algorithm" do
    u = Cat.create!(:name => "master")
    c = Client.create!(:name => "client_master")

    [:slave4, :slave1, :slave2, :slave3].each do |sym|
      Cat.using(sym).create!(:name => "Replicated_#{sym}")
    end

    Client.find(:first).should_not be_nil
    Cat.find(:first).name.should == "Replicated_slave1"
    Client.find(:first).should_not be_nil
    Cat.find(:first).name.should == "Replicated_slave2"
    Client.find(:first).should_not be_nil
    Cat.find(:first).name.should == "Replicated_slave3"
    Client.find(:first).should_not be_nil
    Cat.find(:first).name.should == "Replicated_slave4"
    Client.find(:first).should_not be_nil
    Cat.find(:first).name.should == "Replicated_slave1"
    Client.find(:first).should_not be_nil

    [:slave4, :slave1, :slave2, :slave3].each do |sym|
      Cat.using(sym).find_by_name("master").should be_false
    end
  end
end


describe "when the database is replicated and the entire application is replicated" do
  before(:each) do
    Octopus.stub!(:env).and_return("production_entire_replicated")
    clean_connection_proxy()
  end
  
  it "should send all writes queries to master" do
    u = Client.using(:slave4).create!(:name => "Slave Client")    
    u1 = Client.using(:slave4).first
    u1.name = "Client"
    u1.save()
    Client.using(:slave4).first.name.should == "Slave Client"
  end

  it "should send read queries to slaves,to all models, using a round robin algorithm" do
    u = Cat.create!(:name => "master")
    c = Client.create!(:name => "client_master")

    [:slave4, :slave1, :slave2, :slave3].each do |sym|
      Cat.using(sym).create!(:name => "Replicated_#{sym}")
    end

    [:slave4, :slave1, :slave2, :slave3].each do |sym|
      Client.using(sym).create!(:name => "Replicated_#{sym}")
    end

    Client.find(:first).name.should == "Replicated_slave1"
    Cat.find(:first).name.should == "Replicated_slave2"
    Client.find(:first).name.should == "Replicated_slave3"
    Cat.find(:first).name.should == "Replicated_slave4"
    Cat.find(:first).name.should == "Replicated_slave1"
    Client.find(:first).name.should == "Replicated_slave2"
    Cat.find(:first).name.should == "Replicated_slave3"
    Client.find(:first).name.should == "Replicated_slave4"


    [:slave4, :slave1, :slave2, :slave3].each do |sym|
      Cat.using(sym).find_by_name("master").should be_false
    end
    
    [:slave4, :slave1, :slave2, :slave3].each do |sym|
      Client.using(sym).find_by_name("master").should be_false
    end
  end
end

