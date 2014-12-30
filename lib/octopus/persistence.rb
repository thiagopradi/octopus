module Octopus
  module Rails3
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
    end
  end
end

ActiveRecord::Base.send(:include, Octopus::Rails3::Persistence)
