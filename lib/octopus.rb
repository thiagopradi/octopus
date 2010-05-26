require "yaml"

module Octopus
  def self.file()
    "/Users/tchandy/Projetos/octopus/spec"
  end
  
  def self.config()
    @@config ||= YAML.load_file(Octopus.file() + "/config/shards.yml")
  end
  
  def self.init()

  end
end

require "octopus/migration"
require "octopus/model"
require "octopus/controller"
require "octopus/proxy"

Octopus.init()