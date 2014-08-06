class CreateUsersOnMultiplesGroups < ActiveRecord::Migration
  using_group('country_shards', 'history_shards')

  def self.up
    User.create!(:name => 'MultipleGroup')
  end

  def self.down
    User.delete_all
  end
end
