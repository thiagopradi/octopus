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
    it "should have the default octopus enviroment as production" do
      Octopus.octopus_enviroments.should == ["production"]
    end
    
    it "should allow the user to configure the octopus enviroments" do
      Octopus.setup do |config|
        config.octopus_enviroments = [:production, :staging]
      end
      
      Octopus.octopus_enviroments.should == ['production', 'staging']      

      Octopus.setup do |config|
        config.octopus_enviroments = [:production]
      end
    end
  end
end
