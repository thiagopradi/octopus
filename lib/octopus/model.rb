module Octopus::Model  
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def using(*args)
      @proxy = Octopus::Proxy.new(self, args)
      return self
    end

    def self.connection
      @proxy || superclass.connection
    end

    def self.connected?
      @proxy.connected?
    end
  end
end

ActiveRecord::Base.send(:include, Octopus::Model)