module Octopus
  module Persistence
    def update_attribute(...)
      run_on_shard { super(...) }
    end

    def update_attributes(...)
      run_on_shard { super(...) }
    end

    def update_attributes!(...)
      run_on_shard { super(...) }
    end

    def reload(...)
      run_on_shard { super(...) }
    end

    def delete
      run_on_shard { super }
    end

    def destroy
      run_on_shard { super }
    end

    def touch(...)
      run_on_shard { super(...) }
    end

    def update_column(...)
      run_on_shard { super(...) }
    end

    def increment!(...)
      run_on_shard { super(...) }
    end

    def decrement!(...)
      run_on_shard { super(...) }
    end
  end
end

ActiveRecord::Base.send(:include, Octopus::Persistence)
