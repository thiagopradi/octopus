class AddFieldAgeToUsers < ActiveRecord::Migration
  using(:canada)
  
  def self.up
    add_column :users, :age, :string
  end

  def self.down
    remove_column :users, :age
  end
end