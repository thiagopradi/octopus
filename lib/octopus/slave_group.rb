class Octopus::SlaveGroup
  def initialize(slaves)
    slaves = HashWithIndifferentAccess.new(slaves)
    slaves_list = slaves.values
    @load_balancer = Octopus::LoadBalancing::RoundRobin.new(slaves_list)
  end

  def next
    @load_balancer.next
  end
end
