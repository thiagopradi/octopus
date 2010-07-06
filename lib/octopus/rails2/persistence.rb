class ActiveRecord::Base
  def delete
    self.using(self.current_shard) do
      self.class.delete(id) unless new_record?
      @destroyed = true
      freeze
    end
  end

  def destroy
    self.using(self.current_shard) do
      unless new_record?
        connection.delete(
        "DELETE FROM #{self.class.quoted_table_name} " +
        "WHERE #{connection.quote_column_name(self.class.primary_key)} = #{quoted_id}",
        "#{self.class.name} Destroy"
        )
      end
    end
    @destroyed = true
    freeze
  end

  def reload(options = nil)
    self.using(self.current_shard) do

      clear_aggregation_cache
      clear_association_cache
      @attributes.update(self.class.send(:with_exclusive_scope) { self.class.find(self.id, options) }.instance_variable_get('@attributes'))
      @attributes_cache = {}
      self
    end
  end
end
