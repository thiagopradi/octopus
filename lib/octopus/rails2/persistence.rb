module Octopus::Persistence
  def save
    self.using(self.current_shard) do
      create_or_update
    end
  end

  def save!
    self.using(self.current_shard) do
      create_or_update || raise(RecordNotSaved)
    end
  end

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

  def clone
    attrs = clone_attributes(:read_attribute_before_type_cast)
    attrs.delete(self.class.primary_key)
    record = self.class.new
    record.send :instance_variable_set, '@attributes', attrs
    record
  end

  # Returns an instance of the specified +klass+ with the attributes of the current record. This is mostly useful in relation to
  # single-table inheritance structures where you want a subclass to appear as the superclass. This can be used along with record
  # identification in Action Pack to allow, say, <tt>Client < Company</tt> to do something like render <tt>:partial => @client.becomes(Company)</tt>
  # to render that instance using the companies/company partial instead of clients/client.
  #
  # Note: The new instance will share a link to the same attributes as the original class. So any change to the attributes in either
  # instance will affect the other.
  def becomes(klass)
    returning klass.new do |became|
      became.instance_variable_set("@attributes", @attributes)
      became.instance_variable_set("@attributes_cache", @attributes_cache)
      became.instance_variable_set("@new_record", new_record?)
    end
  end

  # Updates a single attribute and saves the record without going through the normal validation procedure.
  # This is especially useful for boolean flags on existing records. The regular +update_attribute+ method
  # in Base is replaced with this when the validations module is mixed in, which it is by default.
  def update_attribute(name, value)
    send(name.to_s + '=', value)
    save(false)
  end

  # Updates all the attributes from the passed-in Hash and saves the record. If the object is invalid, the saving will
  # fail and false will be returned.
  def update_attributes(attributes)
    self.attributes = attributes
    save
  end

  # Updates an object just like Base.update_attributes but calls save! instead of save so an exception is raised if the record is invalid.
  def update_attributes!(attributes)
    self.attributes = attributes
    save!
  end

  def increment(attribute, by = 1)
    self[attribute] ||= 0
    self[attribute] += by
    self
  end

  def increment!(attribute, by = 1)
    increment(attribute, by).update_attribute(attribute, self[attribute])
  end

  def decrement(attribute, by = 1)
    self[attribute] ||= 0
    self[attribute] -= by
    self
  end

  def decrement!(attribute, by = 1)
    decrement(attribute, by).update_attribute(attribute, self[attribute])
  end

  def toggle(attribute)
    self[attribute] = !send("#{attribute}?")
    self
  end

  def toggle!(attribute)
    toggle(attribute).update_attribute(attribute, self[attribute])
  end

  def reload(options = nil)    
    clear_aggregation_cache
    clear_association_cache
    @attributes.update(self.class.send(:with_exclusive_scope) { self.class.find(self.id, options) }.instance_variable_get('@attributes'))
    @attributes_cache = {}
    self
  end
end

ActiveRecord::Base.send(:include, Octopus::Persistence)