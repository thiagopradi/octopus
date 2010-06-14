class CreateUsersUsingReplication < ActiveRecord::Migration
  def self.up
    Cat.create!(:name => "Replication")
  end

  def self.down
    Cat.delete_all()
  end
end