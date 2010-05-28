require "yaml"

module Octopus
  def self.file()
    "/Users/tchandy/Projetos/octopus/spec"
  end
  
  def self.config()
    @@config ||= YAML.load_file(Octopus.file() + "/config/shards.yml")
  end
  
  def self.connect()
    ActiveRecord::Base.cattr_accessor :connection_proxy
    ActiveRecord::Base.cattr_accessor :current_shard
    ActiveRecord::Base.connection_proxy = Octopus::Proxy.new(Octopus.config())  
  end  
end

require "octopus/migration"
require "octopus/model"
require "octopus/controller"
require "octopus/proxy"

Octopus.connect()