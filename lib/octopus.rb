require "yaml"

module Octopus
  def self.env()
    @env ||= defined?(Rails) ? Rails.env.to_s : "octopus"      
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
require "octopus/persistence"
require "octopus/controller"
require "octopus/association"
require "octopus/association_collection"
require "octopus/scope_proxy"
require "octopus/has_and_belongs_to_many_association"