class CreateUsersUsingBlockAndUsing < ActiveRecord::Migration
  using(:brazil)

  def self.up
    Octopus.using(:canada) do
      User.create!(:name => "Canada")
    end

    User.create!(:name => "Brazil")
  end

  def self.down
    User.delete_all()
  end
end