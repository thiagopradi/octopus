class CreateUserOnShardsOfDefaultGroupWithVersions < ActiveRecord::Migration[ActiveRecord::VERSION::STRING[0..2]]
  def self.up
    User.create!(:name => 'Default Group')
  end

  def self.down
    User.delete_all
  end
end
