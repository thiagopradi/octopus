class CreateUsersOnShardsOfAGroup < ActiveRecord::Migration
  using_group(:country_shards)

  def self.up
    User.create!(:name => "Group")
  end

  def self.down
    User.delete_all()
  end
end