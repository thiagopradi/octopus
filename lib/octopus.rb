require "yaml"

module Octopus
  def self.env()
    @env ||= 'octopus'
  end
  
  def self.config()
    @config ||= YAML.load_file(Octopus.directory() + "/config/shards.yml") 
  end

  # Returns the Rails.root_to_s when you are using rails
  # Running the current directory in a generic Ruby process
  def self.directory()
    @directory ||= defined?(Rails) ?  Rails.root.to_s : Dir.pwd     
  end
  
  # This is the default way to do Octopus Setup
  # Available variables:
  # :excluded_enviroments => the enviroments that octopus will not run. default: :development, :cucumber and :test
  def self.setup
    yield self
  end
  
  def self.excluded_enviroments=(excluded_enviroments)
    @excluded_enviroments = excluded_enviroments.map {|element| element.to_s }
  end
  
  def self.excluded_enviroments
    @excluded_enviroments || ['development',"cucumber", "test"]
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