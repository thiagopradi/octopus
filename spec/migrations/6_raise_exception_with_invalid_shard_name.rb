class RaiseExceptionWithInvalidShardName < ActiveRecord::Migration
  using(:amazing_shard)

  def self.up
    User.create!(:name => 'Error')
  end

  def self.down
    User.delete_all
  end
end
