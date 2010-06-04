require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Octopus::Proxy do
  before(:each) do
    @proxy = Octopus::Proxy.new(Octopus.config())
  end

  describe "creating a new instance" do    
    it "should initialize all shards and groups" do
      @proxy.shards.keys.to_set.should == [:alone_shard, :aug2011, :canada, :brazil, :aug2009, :russia, :aug2010, :master].to_set
      @proxy.groups.should == {:country_shards=>[:canada, :brazil, :russia], :history_shards=>[:aug2009, :aug2010, :aug2011]}
    end

    it "should initialize the block attribute as false" do
      @proxy.block.should be_false
    end    
    it "should initialize replicated attribute as false" do
      @proxy.replicated.should be_false      
    end

    describe "should raise error if you have duplicated shard names" do
      before(:each) do
        Octopus.stub!(:env).and_return("production_raise_error")        
      end

      it "should raise the error" do
        lambda { Octopus::Proxy.new(Octopus.config()) }.should raise_error("You have duplicated shard names!")        
      end
    end
  end

  describe "returning the correct connection" do
    describe "should return the shard name" do
      it "when current_shard is empty" do
        @proxy.shard_name.should == :master        
      end

      it "when current_shard is a single shard" do
        @proxy.current_shard = :canada
        @proxy.shard_name.should == :canada        
      end

      it "when current_shard is more than one shard" do
        @proxy.current_shard = [:russia, :brazil]
        @proxy.shard_name.should == :russia              
      end
    end

    describe "should return the connection based on shard_name" do
      it "when current_shard is empty" do
        @proxy.select_connection().should == @proxy.shards[:master].connection()        
      end

      it "when current_shard is a single shard" do
        @proxy.current_shard = :canada
        @proxy.select_connection().should == @proxy.shards[:canada].connection()       
      end
    end
  end

  describe "when the database is replicated" do
    before(:each) do
      Octopus.stub!(:env).and_return("production_replicated")
      @proxy = Octopus::Proxy.new(Octopus.config())
      ActiveRecord::Base.stub!(:connection_proxy).and_return(@proxy) 
      User.stub!(:connection_proxy).and_return(@proxy)      
    end
    
    it "should have the replicated attribute as true" do
      @proxy.replicated.should be_true
    end

    it "should initialize the list of shards" do
      @proxy.slaves_list.should == ["slave1", "slave2", "slave3", "slave4"]
    end

    it "should send all writes queries to master" do
      u = User.create!(:name => "Replicated")

      [:slave4, :slave1, :slave2, :slave3].each do |sym|
        User.using(sym).count.should == 0
      end

      User.using(:master).count.should == 1
    end

    it "should send read queries to slaves, using a round robin algorithm" do
      #create on master
      u = User.create!(:name => "master")

      [:slave4, :slave1, :slave2, :slave3].each do |sym|
        User.using(sym).create!(:name => "Replicated_#{sym}")
      end

      User.find(:first).name.should == "Replicated_slave1"
      User.find(:first).name.should == "Replicated_slave2"
      User.find(:first).name.should == "Replicated_slave3"
      User.find(:first).name.should == "Replicated_slave4"
      User.find(:first).name.should == "Replicated_slave1"
      
      [:slave4, :slave1, :slave2, :slave3].each do |sym|
        User.using(sym).find_by_name("master").should be_false
      end
    end
  end
end