require 'active_record'
require 'active_support/version'
require 'active_support/core_ext/class'

require 'yaml'
require 'erb'

module Octopus
  def self.env
    @env ||= 'octopus'
  end

  def self.rails_env
    @rails_env ||= self.rails? ? Rails.env.to_s : 'shards'
  end

  def self.config
    @config ||= begin
      file_name = Octopus.directory + '/config/shards.yml'

      if File.exist?(file_name) || File.symlink?(file_name)
        config ||= HashWithIndifferentAccess.new(YAML.load(ERB.new(File.read(file_name)).result))[Octopus.env]
      else
        config ||= HashWithIndifferentAccess.new
      end

      config
    end
  end

  # Public: Whether or not Octopus is configured and should hook into the
  # current environment. Checks the environments config option for the Rails
  # environment by default.
  #
  # Returns a boolean
  def self.enabled?
    if defined?(::Rails)
      Octopus.environments.include?(Rails.env.to_s)
    else
      # TODO: This doens't feel right but !Octopus.config.blank? is breaking a
      #       test. Also, Octopus.config is always returning a hash.
      Octopus.config
    end
  end

  # Returns the Rails.root_to_s when you are using rails
  # Running the current directory in a generic Ruby process
  def self.directory
    @directory ||= defined?(Rails) ?  Rails.root.to_s : Dir.pwd
  end

  # This is the default way to do Octopus Setup
  # Available variables:
  # :enviroments => the enviroments that octopus will run. default: 'production'
  def self.setup
    yield self
  end

  def self.environments=(environments)
    @environments = environments.map(&:to_s)
  end

  def self.environments
    @environments ||= config['environments'] || ['production']
  end

  def self.robust_environments=(environments)
    @robust_environments = environments.map(&:to_s)
  end

  # Environments in which to swallow failures from a single shard
  # when iterating through all.
  def self.robust_environments
    @robust_environments ||= config['robust_environments'] || ['production']
  end

  def self.robust_environment?
    robust_environments.include? rails_env
  end

  def self.rails3?
    ActiveRecord::VERSION::MAJOR <= 3
  end

  def self.rails4?
    ActiveRecord::VERSION::MAJOR >= 4
  end

  def self.rails41?
    rails4? && ActiveRecord::VERSION::MINOR >= 1
  end

  def self.rails?
    defined?(Rails)
  end

  attr_writer :logger

  def self.logger
    if defined?(Rails)
      @logger ||= Rails.logger
    else
      @logger ||= Logger.new($stderr)
    end
  end

  def self.shards=(shards)
    config[rails_env] = HashWithIndifferentAccess.new(shards)
    ActiveRecord::Base.connection.initialize_shards(@config)
  end

  def self.using(shard, &block)
    conn = ActiveRecord::Base.connection

    if conn.is_a?(Octopus::Proxy)
      conn.run_queries_on_shard(shard, &block)
    else
      yield
    end
  end

  def self.fully_replicated(&_block)
    old_fully_replicated = Thread.current['octopus.fully_replicated']
    Thread.current['octopus.fully_replicated'] = true
    yield
  ensure
    Thread.current['octopus.fully_replicated'] = old_fully_replicated
  end
end

require 'octopus/shard_tracking'
require 'octopus/shard_tracking/attribute'
require 'octopus/shard_tracking/dynamic'

require 'octopus/model'
require 'octopus/migration'
require 'octopus/association'
require 'octopus/collection_association'
require 'octopus/has_and_belongs_to_many_association' unless Octopus.rails41?
require 'octopus/association_shard_tracking'
require 'octopus/persistence'
require 'octopus/log_subscriber'
require 'octopus/abstract_adapter'
require 'octopus/singular_association'

require 'octopus/railtie' if defined?(::Rails)

require 'octopus/proxy'
require 'octopus/collection_proxy'
require 'octopus/relation_proxy'
require 'octopus/scope_proxy'
