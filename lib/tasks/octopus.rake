namespace :octopus do
  desc "Copy schema version information from master to all shards"
  task :copy_schema_versions => :environment do
    abort("Octopus is not enabled for this environment") unless Octopus.enabled?

    connection = ActiveRecord::Base.connection

    current_version  = ActiveRecord::Migrator.current_version
    migrations_paths = if Octopus.rails_above_30?
                         ActiveRecord::Migrator.migrations_paths
                       else
                         ActiveRecord::Migrator.migrations_path
                       end

    connection.send_queries_to_multiple_shards(connection.shard_names) do
      ActiveRecord::Schema.initialize_schema_migrations_table
      ActiveRecord::Schema.assume_migrated_upto_version(current_version, migrations_paths)
    end
  end
end
