class CreateUsersOnBothShards < ActiveRecord::Migration[ActiveRecord::VERSION::STRING[0..2]]
  using(:brazil, :canada)

  def self.up
    User.create!(:name => 'Both')
  end

  def self.down
    User.delete_all
  end
end
