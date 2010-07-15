module Octopus::Association
  def self.extended(base)
    base.send(:include, InstanceMethods)
  end

  module InstanceMethods
    def set_connection_on_association(record)
      record.current_shard = self.connection.current_shard = self.current_shard if should_set_current_shard?
    end
  end

  def has_many(association_id, options = {}, &extension)
    default_octopus_opts(options)
    super
  end

  def has_and_belongs_to_many(association_id, options = {}, &extension)
    default_octopus_opts(options)
    super
  end

  def default_octopus_opts(options)
    if options[:before_add].is_a?(Array)
      options[:before_add] << :set_connection_on_association
    else
      options[:before_add] = :set_connection_on_association
    end

    if options[:before_remove].is_a?(Array)
      options[:before_remove] << :set_connection_on_association
    else
      options[:before_remove] = :set_connection_on_association
    end
  end
end

ActiveRecord::Base.extend(Octopus::Association)