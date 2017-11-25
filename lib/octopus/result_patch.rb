module Octopus::ResultPatch
  attr_accessor :current_shard

  private

  def hash_rows
    if current_shard.blank?
      super
    else
      foo = super
      foo.each { |f| f.merge!('current_shard' => current_shard) }
      foo
    end
  end
end

class ActiveRecord::Result
  prepend Octopus::ResultPatch
end
