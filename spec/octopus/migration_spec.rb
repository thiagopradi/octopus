require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Octopus::Migration do    
  it "should run just in the master shard" do
    ActiveRecord::Migrator.run(:up, MIGRATIONS_ROOT, 1)

    User.using(:master).find_by_name("Master").should_not be_nil    
    User.using(:canada).find_by_name("Master").should be_nil

    ActiveRecord::Migrator.run(:down, MIGRATIONS_ROOT, 1)
  end

  it "should run on specific shard" do
    ActiveRecord::Migrator.run(:up, MIGRATIONS_ROOT, 2)

    User.using(:master).find_by_name("Sharding").should be_nil    
    User.using(:canada).find_by_name("Sharding").should_not be_nil

    ActiveRecord::Migrator.run(:down, MIGRATIONS_ROOT, 2)
  end

  it "should run on specifieds shards" do
    ActiveRecord::Migrator.run(:up, MIGRATIONS_ROOT, 3)

    User.using(:brazil).find_by_name("Both").should_not be_nil    
    User.using(:canada).find_by_name("Both").should_not be_nil

    ActiveRecord::Migrator.run(:down, MIGRATIONS_ROOT, 3)
  end
  
  it "should run on specified group" do
    ActiveRecord::Migrator.run(:up, MIGRATIONS_ROOT, 4)

    User.using(:canada).find_by_name("Group").should_not be_nil
    User.using(:brazil).find_by_name("Group").should_not be_nil    
    User.using(:russia).find_by_name("Group").should_not be_nil

    ActiveRecord::Migrator.run(:down, MIGRATIONS_ROOT, 4)
  end
  #  
  #  it "should run on slaves on replication" do
  #    pending()
  #  end
  #  
  #  it "should run in all shards, master or another shards" do
  #    pending()
  #  end
end

