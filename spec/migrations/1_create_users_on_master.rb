class CreateUsersOnMaster < ActiveRecord::Migration
  def self.up
    User.create!(:name => 'Master')
  end

  def self.down
    User.delete_all
  end
end
