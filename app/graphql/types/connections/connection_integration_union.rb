class Types::Connections::ConnectionIntegrationUnion < Types::BaseUnion
  description "Objects which may be connected to the system"
  possible_types Types::Connections::PlaidItemType

  # Optional: if this method is defined, it will override `Schema.resolve_type`
  def self.resolve_type(object, context)
    if object.is_a?(PlaidItem)
      Types::Connections::PlaidItemType
    else
      raise RuntimeError.new("Unknown object type #{object.class}")
    end
  end
end
