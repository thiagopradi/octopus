require "yaml"

module Octopus
  def self.config()
    @@config ||= YAML.load_file(Octopus.directory() + "/config/shards.yml")
  end

  def self.directory()
    if defined?(Rails)
      Rails.root.to_s
    else
      File.expand_path(File.join(File.dirname(__FILE__), "..", "spec"))
    end
  end
end

require "octopus/proxy"
require "octopus/migration"
require "octopus/model"
require "octopus/controller"
