class CreateUsersUsingReplication < ActiveRecord::Migration[ActiveRecord::VERSION::STRING[0..2]]
  def self.up
    Cat.create!(:name => 'Replication')
  end

  def self.down
    Cat.delete_all
  end
end
