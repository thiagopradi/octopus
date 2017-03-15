class RaiseExceptionWithInvalidGroupName < ActiveRecord::Migration[ActiveRecord::VERSION::STRING[0..2]]
  using_group(:invalid_group)

  def self.up
    User.create!(:name => 'Error')
  end

  def self.down
    User.delete_all
  end
end
