class RaiseExceptionWithInvalidGroupName < ActiveRecord::Migration
  using_group(:invalid_group)

  def self.up
    User.create!(:name => "Error")
  end

  def self.down
    User.delete_all()
  end
end