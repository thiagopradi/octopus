class CreateUsersOnShardsOfAGroupWithVersions < ActiveRecord::Migration[ActiveRecord::VERSION::STRING[0..2]]
  using_group(:country_shards)

  def self.up
    User.create!(:name => 'Group')
  end

  def self.down
    User.delete_all
  end
end
