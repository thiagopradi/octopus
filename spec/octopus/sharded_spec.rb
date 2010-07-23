require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "when the database is replicated" do
  before(:each) do
    
  end
  
  it "should not send all queries to the specified slave" do
    Octopus.using(:russia) do
    
    end
  end
end