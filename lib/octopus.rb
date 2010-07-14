require "yaml"

module Octopus
  def self.env()
   @env ||= 'octopus'
  end
  
  def self.rails_env()
    @rails_env ||= self.rails? ? Rails.env.to_s : 'shards'
  end
  
  def self.config()
    @config ||= HashWithIndifferentAccess.new(YAML.load_file(Octopus.directory() + "/config/shards.yml"))
    
    if !@config[Octopus.env].nil? && @config[Octopus.env()]['enviroments']
      self.enviroments = @config[Octopus.env()]['enviroments']
    end
    
    @config
  end

  # Returns the Rails.root_to_s when you are using rails
  # Running the current directory in a generic Ruby process
  def self.directory()
    @directory ||= defined?(Rails) ?  Rails.root.to_s : Dir.pwd     
  end
  
  # This is the default way to do Octopus Setup
  # Available variables:
  # :enviroments => the enviroments that octopus will run. default: :production
  def self.setup
    yield self
  end
  
  def self.enviroments=(enviroments)
    @enviroments = enviroments.map { |element| element.to_s }
  end
  
  def self.enviroments
    @enviroments || ['production']
  end
  
  def self.rails3?
    ActiveRecord::VERSION::MAJOR == 3
  end
  
  def self.rails?
    defined?(Rails) 
  end
end


require "octopus/model"
require "octopus/migration"
require "octopus/association_collection"
require "octopus/has_and_belongs_to_many_association"
require "octopus/association"

if Octopus.rails3?
  require "octopus/rails3/association"
  require "octopus/rails3/persistence"
else
  require "octopus/rails2/association"
  require "octopus/rails2/persistence"
end

require "octopus/proxy"
require "octopus/scope_proxy"
require "octopus/controller"

