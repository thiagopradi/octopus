module Octopus
  module Persistence
    def update_attribute(*args)
      run_on_shard { super }
    end

    def update_attributes(*args)
      run_on_shard { super }
    end

    def update_attributes!(*args)
      run_on_shard { super }
    end

    def reload(*args)
      run_on_shard { super }
    end

    def delete
      run_on_shard { super }
    end

    def destroy
      run_on_shard { super }
    end

    def touch(*args)
      run_on_shard { super }
    end

    def update_column(*args)
      run_on_shard { super }
    end

    def increment!(...)
      run_on_shard { super(...) }
    end

    def decrement!(*args)
      run_on_shard { super }
    end
  end
end

ActiveRecord::Base.send(:include, Octopus::Persistence)
