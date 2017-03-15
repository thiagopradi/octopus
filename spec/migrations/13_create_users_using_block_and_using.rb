class CreateUsersUsingBlockAndUsing < ActiveRecord::Migration[ActiveRecord::VERSION::STRING[0..2]]
  using(:brazil)

  def self.up
    Octopus.using(:canada) do
      User.create!(:name => 'Canada')
    end

    User.create!(:name => 'Brazil')
  end

  def self.down
    User.delete_all
  end
end
