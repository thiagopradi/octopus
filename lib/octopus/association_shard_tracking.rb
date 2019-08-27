module Octopus
  module AssociationShardTracking
    def self.extended(base)
      base.send(:include, InstanceMethods)
    end

    module InstanceMethods
      def connection_on_association=(record)
        return unless ::Octopus.enabled?
        return if !self.class.connection.respond_to?(:current_shard) || !self.respond_to?(:current_shard)
        if !record.current_shard.nil? && !current_shard.nil? && record.current_shard.to_s != current_shard.to_s
          fail 'Association Error: Records are from different shards'
        end

        record.current_shard = self.class.connection.current_shard = current_shard if should_set_current_shard?
      end
    end

    if Octopus.rails4?
      def has_many(association_id, scope = nil, options = {}, &extension)
        if options == {} && scope.is_a?(Hash)
          default_octopus_opts(scope)
        else
          default_octopus_opts(options)
        end
        super
      end

      def has_and_belongs_to_many(association_id, scope = nil, options = {}, &extension)
        if options == {} && scope.is_a?(Hash)
          default_octopus_opts(scope)
        else
          default_octopus_opts(options)
        end
        super
      end

    else
      def has_many(association_id, options = {}, &extension)
        default_octopus_opts(options)
        super
      end

      def has_and_belongs_to_many(association_id, options = {}, &extension)
        default_octopus_opts(options)
        super
      end
    end

    def default_octopus_opts(options)
      options[:before_add] = [ :connection_on_association=, options[:before_add] ].compact.flatten
      options[:before_remove] = [ :connection_on_association=, options[:before_remove] ].compact.flatten
    end
  end
end

ActiveRecord::Base.extend(Octopus::AssociationShardTracking)
