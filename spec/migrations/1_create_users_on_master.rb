class CreateUsersOnMaster < ActiveRecord::Migration[ActiveRecord::VERSION::STRING[0..2]]
  def self.up
    User.create!(:name => 'Master')
  end

  def self.down
    User.delete_all
  end
end
