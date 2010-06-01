require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Octopus::Proxy do
  before(:each) do
    @proxy = Octopus::Proxy.new(Octopus.config())
  end
  
  describe "creating a new instance" do    
    it "should initialize all shards and groups" do
      @proxy.shards.keys.to_set.should == [:aug2011, :canada, :brazil, :aug2009, :russia, :aug2010, :master].to_set
      @proxy.groups.should == {:country_shards=>[:canada, :brazil, :russia], :history_shards=>[:aug2009, :aug2010, :aug2011]}
    end
    
    it "should initialize all blocks and multiple shards as false" do
      @proxy.block.should be_false
      @proxy.multiple_shards.should be_false
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
  
  describe "acting as a proxy" do
    
  end
end