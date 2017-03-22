module Octopus
  module Persistence
    def self.included(base)
      base.sharded_methods :update_attribute, :update_attributes, :update_attributes!, :reload,
      :delete, :destroy, :touch, :update_column, :increment!, :decrement!
    end
  end
end

ActiveRecord::Base.send(:include, Octopus::Persistence)
