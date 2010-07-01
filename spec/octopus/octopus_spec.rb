require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Octopus do
  describe "#config method" do
    it "should load shards.yml file to start working" do
      Octopus.config().should be_kind_of(Hash)
    end
  end

  describe "#directory method" do
    it "should return the directory that contains the shards.yml file" do
      Octopus.directory().should == File.expand_path(File.dirname(__FILE__) + "/../")
    end
  end

  describe "#env method" do
    it "should return 'production' when is outside of a rails application" do
      Octopus.env().should == 'octopus'
    end
  end
  
  describe "#setup method" do
    it "should load from YAML" do
      Octopus.excluded_enviroments.should == ["cucumber", "test", "staging"]       
    end
    
    it "should have the default excluded enviroments" do
      Octopus.instance_variable_set(:@excluded_enviroments, nil)
      Octopus.excluded_enviroments.should == ["development", "cucumber", "test"]
    end
    
    it "should configure the excluded enviroments" do
      Octopus.setup do |config|
        config.excluded_enviroments = [:cucumber, :test]
      end
      
      Octopus.excluded_enviroments.should == ['cucumber', 'test']      

      Octopus.setup do |config|
        config.excluded_enviroments = [:cucumber, :test, :staging]
      end
    end
  end
end
