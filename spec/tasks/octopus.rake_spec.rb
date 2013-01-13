require "spec_helper"
require "rake"

describe "octopus.rake" do
  before do
    load File.expand_path("../../../lib/tasks/octopus.rake", __FILE__)
    Rake::Task.define_task(:environment)
  end

  describe "octopus:copy_schema_versions" do
    class SchemaMigration < ActiveRecord::Base; end

    before do
      Rake::Task["octopus:copy_schema_versions"].reenable

      path = File.expand_path("../../migrations", __FILE__)
      if Octopus.rails31? || Octopus.rails32?
        ActiveRecord::Migrator.migrations_paths = [path]
      else
        ActiveRecord::Migrator.stub(:migrations_path => path)
      end
    end

    it "assumes each shard migrated to the current master version" do
      SchemaMigration.create(:version => 1)
      SchemaMigration.create(:version => 2)
      SchemaMigration.create(:version => 3)

      Rake::Task["octopus:copy_schema_versions"].invoke

      ActiveRecord::Base.connection.shard_names.each do |shard_name|
        Octopus.using(shard_name) { ActiveRecord::Migrator.get_all_versions }.should == [1, 2, 3]
      end
    end
  end
end
