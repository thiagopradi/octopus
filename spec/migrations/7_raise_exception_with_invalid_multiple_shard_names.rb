class RaiseExceptionWithInvalidMultipleShardNames < ActiveRecord::Migration
  using(:brazil, :invalid_shard)

  def self.up
    User.create!(:name => 'Error')
  end

  def self.down
    User.delete_all
  end
end
