require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Octopus::Migration do  
  # it "should run just in the master shard" do
  #    pending()
  #  end
  
  it "should run on specific shard" do
    ActiveRecord::Base.using(:master).connection.execute("delete from schema_migrations;")
    ActiveRecord::Base.using(:master).connection.execute("delete from users;")
    ActiveRecord::Migrator.run(:up, MIGRATIONS_ROOT, 1)

    User.using(:master).find_by_name("Sharding").should be_nil    
    User.using(:canada).find_by_name("Sharding").should_not be_nil

    ActiveRecord::Migrator.run(:down, MIGRATIONS_ROOT, 1)
    ActiveRecord::Base.using(:canada).connection.execute("delete from schema_migrations;")
    ActiveRecord::Base.using(:canada).connection.execute("delete from users;")
  end
  
  # it "should run on specifieds shards" do
  #    pending()
  #  end
  #  
  #  it "should run on slaves on replication" do
  #    pending()
  #  end
  #  
  #  it "should run in all shards, master or another shards" do
  #    pending()
  #  end
end

