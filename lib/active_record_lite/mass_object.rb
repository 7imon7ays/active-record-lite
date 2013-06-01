class MassObject
  def self.set_attrs(*attributes)
    @attributes = attributes
    @attributes.each do |attribute|
      attr_accessor attribute
    end
  end

  def self.attributes
    @attributes
  end

  def self.parse_all(results)
    found_objects = []
    results.each do |result_hash|
      found_objects << new(result_hash)
    end
    found_objects
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      if self.class.attributes.include?(attr_name.to_sym)
        self.send("#{attr_name}=", value)
      else
        raise "mass assignment to unregistered attribute #{attr_name}"
      end
    end
  end
end
