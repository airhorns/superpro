class Types::Connections::ConnectionIntegrationUnion < Types::BaseUnion
  description "Objects which may be connected to the system"
  possible_types Types::Connections::PlaidItemType, Types::Connections::ShopifyShopType, Types::Connections::GoogleAnalyticsCredentialType

  # Optional: if this method is defined, it will override `Schema.resolve_type`
  def self.resolve_type(object, _context)
    if object.is_a?(PlaidItem)
      Types::Connections::PlaidItemType
    elsif object.is_a?(ShopifyShop)
      Types::Connections::ShopifyShopType
    elsif object.is_a?(GoogleAnalyticsCredential)
      Types::Connections::GoogleAnalyticsCredentialType
    else
      raise RuntimeError.new("Unknown object type #{object.class}")
    end
  end
end
