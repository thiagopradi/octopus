module Octopus
  module Persistence
    def update_column(*args)
      reload_connection()
      super
    end
  end
end

ActiveRecord::Base.send(:include, Octopus::Persistence)
