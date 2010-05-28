module Octopus::Migration
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    mattr_accessor :current_shard
    
    def using(args)
      ActiveRecord::Base.current_shard = args
      return self
    end
  end
end

ActiveRecord::Migration.send(:include, Octopus::Migration)