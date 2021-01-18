module Octopus
  class SlaveGroup
    def initialize(slaves)
      @name_index_map = HashWithIndifferentAccess.new
      @slaves_list, index = [], 0

      slaves.each do |name, db_connection_pool|
        @slaves_list << db_connection_pool
        @name_index_map[name] = index
        index += 1
      end

      @load_balancer = Octopus.load_balancer.new(@slaves_list)
    end

    def slaves
      @slaves_list
    end

    def has_slave?(slave_name)
      @name_index_map.has_key?(slave_name)
    end

    def next(slave_name = nil)
      @load_balancer.next(@name_index_map[slave_name])
    end

  end
end
