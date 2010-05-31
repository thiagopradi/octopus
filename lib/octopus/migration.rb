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
    def using(args)
      ActiveRecord::Base.connection_proxy().block = true
      ActiveRecord::Base.connection_proxy().current_shard = args
      return self
    end
  end
end

ActiveRecord::Migration.send(:include, Octopus::Migration)