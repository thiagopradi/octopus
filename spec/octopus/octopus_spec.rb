require "spec_helper"

describe Octopus do
  describe "#config" do
    it "should load shards.yml file to start working" do
      Octopus.config().should be_kind_of(HashWithIndifferentAccess)
    end

    describe "when config file doesn't exist" do
      before(:each) do
        Octopus.stub!(:directory).and_return('/tmp')
        Octopus.instance_variable_set(:@config, nil)
      end

      it "should return an empty HashWithIndifferentAccess" do
        Octopus.config().should == HashWithIndifferentAccess.new
      end
    end
  end

  describe "#directory" do
    it "should return the directory that contains the shards.yml file" do
      Octopus.directory().should == File.expand_path(File.dirname(__FILE__) + "/../")
    end
  end

  describe "#env" do
    it "should return 'production' when is outside of a rails application" do
      Octopus.env().should == 'octopus'
    end
  end


  describe "#shards=" do
    after(:each) do
      Octopus.instance_variable_set(:@config, nil)
      Thread.current[:connection_proxy] = Octopus::Proxy.new
    end

    it "should permit users to configure shards on initializer files, instead of on a yml file." do
      lambda { User.using(:crazy_shard).create!(:name => "Joaquim") }.should raise_error

      Octopus.setup do |config|
        config.shards = {:crazy_shard => {:adapter => "mysql", :database => "octopus_shard_5", :username => "root", :password => ""}}
      end

      lambda { User.using(:crazy_shard).create!(:name => "Joaquim")  }.should_not raise_error
    end
  end

  describe "#setup" do
    it "should have the default octopus environment as production" do
      Octopus.environments.should == ["production"]
    end

    it "should allow the user to configure the octopus environments" do
      Octopus.setup do |config|
        config.environments = [:production, :staging]
      end

      Octopus.environments.should == ['production', 'staging']

      Octopus.setup do |config|
        config.environments = [:production]
      end
    end
  end
end
