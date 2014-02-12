require "spec_helper"

describe Octopus::Relation do
  describe "shard tracking" do
    before :each do
      @client = Client.using(:canada).create!
      @client.items.create!
      @relation = @client.items
    end

    it "remembers the shard on which a relation was created" do
      @relation.current_shard.should eq(:canada)
    end

    it "computes the size of the relation without loading it" do
      @relation.size.should eq(1)
      @relation.should_not be_loaded
    end

    context "when no explicit shard context is provided" do
      it "uses the correct shard" do
        @relation.count.should eq(1)
      end

      it "lazily evaluates on the correct shard" do
        @relation.select(:client_id).count.should == 1
      end
    end

    context "when an explicit, but different, shard context is provided" do
      it "uses the correct shard" do
        Item.using(:brazil).count.should eq(0)
        clients_on_brazil = Client.using(:brazil).all
        Client.using(:brazil) do
          @relation.count.should eq(1)
        end
      end

      it "lazily evaluates on the correct shard" do
        Item.using(:brazil).count.should eq(0)
        Client.using(:brazil) do
          @relation.select(:client_id).count.should == 1
        end
      end
    end
  end
end
