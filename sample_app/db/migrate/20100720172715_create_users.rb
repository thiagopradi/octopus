class CreateUsers < ActiveRecord::Migration
  using(:master, :asia, :europe, :america)

  def self.up
    create_table :users do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
