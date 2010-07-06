require "yaml"

module Octopus
  def self.env()
    @env ||= defined?(Rails) ? Rails.env.to_s : 'octopus'
  end
  
  def self.config()
    @config ||= HashWithIndifferentAccess.new(YAML.load_file(Octopus.directory() + "/config/shards.yml"))
    
    if !@config[Octopus.env].nil? && @config[Octopus.env()]['excluded_enviroments']
      self.excluded_enviroments = @config[Octopus.env()]['excluded_enviroments']
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
  # :excluded_enviroments => the enviroments that octopus will not run. default: :development, :cucumber and :test
  def self.setup
    yield self
  end
  
  def self.excluded_enviroments=(excluded_enviroments)
    @excluded_enviroments = excluded_enviroments.map { |element| element.to_s }
  end
  
  def self.excluded_enviroments
    @excluded_enviroments || ['development',"cucumber", "test"]
  end
  
  def self.rails3?
    ActiveRecord::VERSION::MAJOR == 3
  end
end


require "octopus/model"
require "octopus/migration"

if Octopus.rails3?
  require "octopus/rails3/association"
  require "octopus/rails3/association_collection"
  require "octopus/rails3/has_and_belongs_to_many_association"
  require "octopus/rails3/persistence"
else
  require "octopus/rails2/association"
  require "octopus/rails2/association_collection"
  require "octopus/rails2/has_and_belongs_to_many_association"
  require "octopus/rails2/persistence"
end

require "octopus/proxy"
require "octopus/scope_proxy"
require "octopus/controller"

