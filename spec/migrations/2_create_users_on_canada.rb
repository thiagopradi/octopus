class CreateUsersOnCanada < ActiveRecord::Migration[ActiveRecord::VERSION::STRING[0..2]]
  using(:canada)

  def self.up
    User.create!(:name => 'Sharding')
  end

  def self.down
    User.delete_all
  end
end
