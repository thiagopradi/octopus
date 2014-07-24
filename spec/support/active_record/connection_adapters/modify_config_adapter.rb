module ActiveRecord
  class Base
    def self.modify_config_connection(config)
      ConnectionAdapters::ModifyConfigAdapter.new(config)
    end
  end

  module ConnectionAdapters
    class ModifyConfigAdapter < AbstractAdapter
      def initialize(config)
        config.replace(config.symbolize_keys)
      end
    end
  end
end
