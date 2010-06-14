class CreateUsersUsingReplication < ActiveRecord::Migration
  def self.up
    User.create!(:name => "Replication")
  end

  def self.down
    User.delete_all()
  end
end