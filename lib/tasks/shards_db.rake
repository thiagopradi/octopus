namespace :db do
  namespace :shards do
    desc 'Create shard DB'
    task create: :load_config do
      include ActiveRecord::Tasks

      shard = ENV['SHARD']
      rails_env = ENV['RAILS_ENV'] || "development"

      DatabaseTasks.database_configuration = Octopus.config[rails_env][rails_env]

      if shard
        DatabaseTasks.create(DatabaseTasks.database_configuration[shard]) unless DatabaseTasks.database_configuration[shard].nil?
      else
        DatabaseTasks.database_configuration.each do |_, value|
          DatabaseTasks.create(value)
        end
      end
    end

    desc 'Drop shard DB'
    task drop: :load_config do
      include ActiveRecord::Tasks

      shard = ENV['SHARD']
      rails_env = ENV['RAILS_ENV'] || "development"

      DatabaseTasks.database_configuration = Octopus.config[rails_env][rails_env]

      if shard
        DatabaseTasks.drop(DatabaseTasks.database_configuration[shard]) unless DatabaseTasks.database_configuration[shard].nil?
      else
        DatabaseTasks.database_configuration.each do |_, value|
          DatabaseTasks.drop(value)
        end
      end
    end
  end
