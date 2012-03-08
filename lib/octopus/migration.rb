module Octopus::Migration
  def self.extended(base)
    class << base
      def announce_with_octopus(message)
        announce_without_octopus("#{message} - #{get_current_shard}")
      end

      alias_method_chain :migrate, :octopus
      alias_method_chain :announce, :octopus
      attr_accessor :current_shard
    end
  end

  def self.included(base)
    base.class_eval do
      def announce_with_octopus(message)
        announce_without_octopus("#{message} - #{get_current_shard}")
      end

      alias_method_chain :migrate, :octopus
      alias_method_chain :announce, :octopus
      attr_accessor :current_shard
    end
  end

  def using(*args)
    if self.connection().is_a?(Octopus::Proxy)
      args.each do |shard|
        self.connection().check_schema_migrations(shard)
      end

      self.connection().block = true
      self.current_shard = args
      self.connection().current_shard = args
    end

    return self
  end

  def using_group(*groups)
    if self.connection.is_a?(Octopus::Proxy)
      groups.each do |group|
        shards = self.connection.shards_for_group(group) || []

        shards.each do |shard|
          self.connection.check_schema_migrations(shard)
        end
      end

      self.connection.block = true
      self.connection.current_group = groups
    end

    self
  end

  def get_current_shard
    "Shard: #{ActiveRecord::Base.connection.current_shard()}" if ActiveRecord::Base.connection.respond_to?(:current_shard)
  end

  def migrate_with_octopus(direction)
    conn = ActiveRecord::Base.connection
    return migrate_without_octopus(direction) unless conn.is_a?(Octopus::Proxy)
    self.connection().current_shard = self.current_shard if self.current_shard != nil

    begin
      shards = Set.new

      if conn.current_group
        [conn.current_group].flatten.each do |group|
          group_shards = conn.shards_for_group(group)
          shards.merge(group_shards) if group_shards
        end
      elsif conn.current_shard.is_a?(Array)
        shards.merge(conn.current_shard)
      end

      if shards.any?
        conn.send_queries_to_multiple_shards(shards.to_a) do
          migrate_without_octopus(direction)
        end
      else
        migrate_without_octopus(direction)
      end
    ensure
      conn.clean_proxy
    end
  end
end

if Octopus.rails31?
  ActiveRecord::Migration.send(:include, Octopus::Migration)
else
  ActiveRecord::Migration.extend(Octopus::Migration)
end
