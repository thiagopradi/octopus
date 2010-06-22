module Octopus::Migration
  def self.extended(base)
    class << base
      def connection
        ActiveRecord::Base.connection_proxy()
      end
    end
  end

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


ActiveRecord::Migration.extend(Octopus::Migration)