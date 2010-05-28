require "yaml"

module Octopus
  def self.config()
    @@config ||= YAML.load_file(Octopus.directory() + "/config/shards.yml")
  end

  def self.connect()
    ActiveRecord::Base.cattr_accessor :connection_proxy
    ActiveRecord::Base.cattr_accessor :current_shard
    ActiveRecord::Base.connection_proxy = Octopus::Proxy.new(Octopus.config())  
  end  

  def self.directory()
    if defined?(Rails)
      Rails.root.to_s
    else
      File.expand_path(File.join(File.dirname(__FILE__), "..", "spec"))
    end
  end
end

require "octopus/migration"
require "octopus/model"
require "octopus/controller"
require "octopus/proxy"

Octopus.connect()