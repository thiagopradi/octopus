module Octopus
  class SlaveGroup
    def initialize(slaves)
      slaves_list = slaves.values
      @load_balancer = Octopus::LoadBalancing::RoundRobin.new(slaves_list)
    end

    def next
      @load_balancer.next
    end
  end
end
