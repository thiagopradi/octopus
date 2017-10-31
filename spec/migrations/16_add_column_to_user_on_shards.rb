class AddColumnToUserOnShards < BaseOctopusMigrationClass
  using(:europe, :brazil, :canada, :russia, :master)

  def change
    add_column :users, :age, :integer
  end
end
