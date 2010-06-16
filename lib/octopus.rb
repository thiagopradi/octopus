require "yaml"

module Octopus
  def self.env()
    @env ||= defined?(Rails) ? Rails.env.to_s : "production"      
  end
  
  def self.config()
    @config ||= YAML.load_file(Octopus.directory() + "/config/shards.yml") 
  end

  # Returns the Rails.root_to_s when you are using rails
  # Running the current directory in a generic Ruby process
  def self.directory()
    @directory ||= defined?(Rails) ?  Rails.root.to_s : Dir.pwd     
  end
end

require "octopus/proxy"
require "octopus/migration"
require "octopus/model"
require "octopus/controller"
require "octopus/association"