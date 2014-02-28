require "spec_helper"

describe Octopus::CollectionProxy do
  describe "method dispatch" do
    before :each do
      @client = Client.using(:canada).create!
      @client.items << Item.using(:canada).create!
    end

    it "computes the size of the collection without loading it" do
      @client.items.size.should eq(1)
      @client.items.should_not be_loaded
    end
  end
end
