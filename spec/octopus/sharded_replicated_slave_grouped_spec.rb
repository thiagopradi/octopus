require "spec_helper"

describe "when the database is both sharded and replicated" do

  it "should pick the shard based on current_shard when you have a sharded model" do

    OctopusHelper.using_environment :sharded_replicated_slave_grouped do
      Octopus.using(:russia) do
        Cat.create!(:name => "Thiago1")
        Cat.create!(:name => "Thiago2")
      end

      # We must stub here to make it effective (not in the `before(:each)` block)
      Octopus.stub(:env).and_return("sharded_replicated_slave_grouped")

      Cat.using(:russia).count.should == 2
      # It distributes queries between two slaves in the slave group
      Cat.using(shard: :russia, slave_group: :slaves1).count.should == 0
      Cat.using(shard: :russia, slave_group: :slaves1).count.should == 2
      Cat.using(shard: :russia, slave_group: :slaves1).count.should == 0
      # It distributes queries between two slaves in the slave group
      Cat.using(shard: :russia, slave_group: :slaves2).count.should == 2
      Cat.using(shard: :russia, slave_group: :slaves2).count.should == 0
      Cat.using(shard: :russia, slave_group: :slaves2).count.should == 2

      Cat.using(:europe).count.should == 0
      Cat.using(shard: :europe, slave_group: :slaves1)
        .count.should == 0
      Cat.using(shard: :europe, slave_group: :slaves2)
        .count.should == 2
    end
  end

  it "should make queries to master when slave groups are configured for the shard but not selected" do
    OctopusHelper.using_environment :sharded_replicated_slave_grouped do
      Octopus.using(:europe) do
        # All the queries go to :master(`octopus_shard_1`)

        Cat.create!(:name => "Thiago1")
        Cat.create!(:name => "Thiago2")

        # In `database.yml` and `shards.yml`, we have configured 1 master and 6 slaves for `sharded_replicated_slave_grouped`
        # So we can ensure Octopus is not distributing queries between them
        # by asserting 1 + 6 = 7 queries go to :master(`octopus_shard_1`)
        Cat.count.should == 2
        Cat.count.should == 2
        Cat.count.should == 2
        Cat.count.should == 2
        Cat.count.should == 2
        Cat.count.should == 2
        Cat.count.should == 2
      end
    end
  end
end
