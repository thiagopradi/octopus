class RaiseExceptionWithInvalidShardName < ActiveRecord::Migration[ActiveRecord::VERSION::STRING[0..2]]
  using(:amazing_shard)

  def self.up
    User.create!(:name => 'Error')
  end

  def self.down
    User.delete_all
  end
end
