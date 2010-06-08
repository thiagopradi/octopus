require "yaml"

module Octopus
  def self.env()
    if defined?(Rails)
      Rails.env.to_s
    else
      "production"
    end
  end
  
  def self.config()
    @@config ||= YAML.load_file(Octopus.directory() + "/config/shards.yml") 
  end

  def self.directory()
    if defined?(Rails)
      # Running in a normal Rails application
      Rails.root.to_s
    else
      # Running in a generic Ruby process
      Dir.pwd
    end
  end
end

require "octopus/proxy"
require "octopus/migration"
require "octopus/model"
require "octopus/controller"
