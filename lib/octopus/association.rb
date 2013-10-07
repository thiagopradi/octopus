module Octopus::Association
  def self.extended(base)
    base.send(:include, InstanceMethods)
  end

  module InstanceMethods
    def set_connection_on_association(record)
      return unless ::Octopus.enabled?
      return if !self.class.connection.respond_to?(:current_shard) || !self.respond_to?(:current_shard)
      if !record.current_shard.nil? && !self.current_shard.nil? && record.current_shard != self.current_shard
        raise "Association Error: Records are from different shards"
      end

      record.current_shard = self.class.connection.current_shard = self.current_shard if should_set_current_shard?
    end
  end

  if Octopus.rails4?
    def has_many(association_id, scope=nil, options={}, &extension)
      if options == {} && scope.is_a?(Hash)
        default_octopus_opts(scope)
      else
        default_octopus_opts(options)
      end
      super
    end
  else
    def has_many(association_id, options={}, &extension)
      default_octopus_opts(options)
      super
    end
  end


  if Octopus.rails4?
    def has_and_belongs_to_many(association_id, scope=nil, options={}, &extension)
      if options == {} && scope.is_a?(Hash)
        default_octopus_opts(scope)
      else
        default_octopus_opts(options)
      end
      super
    end
  else
    def has_and_belongs_to_many(association_id, options={}, &extension)
      default_octopus_opts(options)
      super
    end
  end

  def default_octopus_opts(options)
    if options[:before_add].is_a?(Array)
      options[:before_add] << :set_connection_on_association
    elsif options[:before_add].is_a?(Symbol)
      options[:before_add] = [:set_connection_on_association, options[:before_add]]
    else
      options[:before_add] = :set_connection_on_association
    end

    if options[:before_remove].is_a?(Array)
      options[:before_remove] << :set_connection_on_association
    elsif options[:before_remove].is_a?(Symbol)
      options[:before_remove] = [:set_connection_on_association, options[:before_remove]]
    else
      options[:before_remove] = :set_connection_on_association
    end
  end
end

ActiveRecord::Base.extend(Octopus::Association)
