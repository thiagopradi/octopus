module Octopus
  class SlaveGroup
    def initialize(slaves)
      slaves = HashWithIndifferentAccess.new(slaves)
      slaves_list = slaves.values
      @load_balancer = Octopus.load_balancer.new(slaves_list)
    end

    def next(options)
      @load_balancer.next options
    end
  end
end
