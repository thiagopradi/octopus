module Octopus::Migration
  def self.included(base)
    base.extend(ClassMethods)
    class << base
      def connection
        ActiveRecord::Base.connection_proxy()
      end

      def connected?
        ActiveRecord::Base.connection_proxy().connected?
      end
    end
  end

  module ClassMethods
    def using(*args)
      if args.size == 1
        self.connection().block = true
        self.connection().current_shard = args.first
      else
        self.connection().current_shard = args        
      end

      return self
    end

    def using_group(*args)
      if args.size == 1
        self.connection().block = true
        self.connection().current_group = args.first
      else
        self.connection().current_group = args
      end
      
      return self
    end
  end
end

ActiveRecord::Migration.send(:include, Octopus::Migration)