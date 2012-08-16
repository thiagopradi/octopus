class CreateItems < ActiveRecord::Migration
  using(:master, :asia, :europe, :america)
  
  def self.up
    create_table :items do |t|
      t.string :name
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :items
  end
end
