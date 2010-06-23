describe "when the database is replicated" do
  before(:each) do
    Octopus.stub!(:env).and_return("production_replicated")
    @proxy = Octopus::Proxy.new(Octopus.config())
    clean_connection_proxy()
  end
  
  it "should have the replicated attribute as true" do
    @proxy.replicated.should be_true
  end

  it "should initialize the list of shards" do
    @proxy.instance_variable_get(:@slaves_list).should == ["slave1", "slave2", "slave3", "slave4"]
  end

  it "should send all writes/reads queries to master when you have a replicated model" do
    u = User.create!(:name => "Replicated")
    User.count.should == 1
    User.find(u.id).should == u
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
