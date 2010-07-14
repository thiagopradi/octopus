module Octopus::Association
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
      options[:before_add] << :set_connection
    else
      options[:before_add] = :set_connection
    end

    if options[:before_remove].is_a?(Array)
      options[:before_remove] << :set_connection
    else
      options[:before_remove] = :set_connection
    end
  end
end

ActiveRecord::Base.extend(Octopus::Association)