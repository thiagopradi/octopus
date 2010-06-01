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
        ActiveRecord::Base.connection_proxy().block = true
        ActiveRecord::Base.connection_proxy().current_shard = args.first
      else
        ActiveRecord::Base.connection_proxy().multiple_shards = true
        ActiveRecord::Base.connection_proxy().current_shard = args        
      end
      
      return self
    end
  end
end

ActiveRecord::Migration.send(:include, Octopus::Migration)