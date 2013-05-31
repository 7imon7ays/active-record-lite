class MassObject
  def self.set_attrs(*attributes)
    @attributes = attributes
    attributes.each do |attribute|
      attr_accessor attribute.to_sym
    end
  end

  def self.attributes
  end

  def self.parse_all(results)
  end

  def initialize(params = {})
  end
end
