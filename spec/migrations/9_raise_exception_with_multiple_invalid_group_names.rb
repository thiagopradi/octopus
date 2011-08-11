class RaiseExceptionWithMultipleInvalidGroupNames < ActiveRecord::Migration
  using_group(:country_shards,:invalid_group)

  def self.up
    User.create!(:name => "Error")
  end

  def self.down
    User.delete_all()
  end
end