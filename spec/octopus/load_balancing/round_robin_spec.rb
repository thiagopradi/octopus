require 'spec_helper'

describe Octopus::LoadBalancing::RoundRobin do
  it "raises an error when no shards are given" do
    expect do
      Octopus::LoadBalancing::RoundRobin.new([])
    end.to raise_error Octopus::Exception
  end

  it "does not raise an error if slaves given" do
    expect do
      Octopus::LoadBalancing::RoundRobin.new([:stub])
    end.to_not raise_error Octopus::Exception
  end
end
