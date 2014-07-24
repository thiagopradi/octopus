class CreateUsersOnBothShards < ActiveRecord::Migration
  using(:brazil, :canada)

  def self.up
    User.create!(:name => 'Both')
  end

  def self.down
    User.delete_all
  end
end
