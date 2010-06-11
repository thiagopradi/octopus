class CreateItems < ActiveRecord::Migration
  using(:master, :brazil, :canada, :mexico)
  
  def self.up
    create_table :items do |t|
      t.string :nome

      t.timestamps
    end
  end

  def self.down
    drop_table :items
  end
end
