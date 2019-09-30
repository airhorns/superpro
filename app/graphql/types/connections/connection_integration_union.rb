# frozen_string_literal: true

class Types::Connections::ConnectionIntegrationUnion < Types::BaseUnion
  description "Objects which may be connected to the system"
  possible_types Types::Connections::PlaidItemType, Types::Connections::ShopifyShopType, Types::Connections::GoogleAnalyticsCredentialType, Types::Connections::FacebookAdAccountType

  # Optional: if this method is defined, it will override `Schema.resolve_type`
  def self.resolve_type(object, _context)
    if object.is_a?(PlaidItem)
      Types::Connections::PlaidItemType
    elsif object.is_a?(ShopifyShop)
      Types::Connections::ShopifyShopType
    elsif object.is_a?(GoogleAnalyticsCredential)
      Types::Connections::GoogleAnalyticsCredentialType
    elsif object.is_a?(FacebookAdAccount)
      Types::Connections::FacebookAdAccountType
    else
      raise "Unknown object type #{object.class}"
    end
  end
end
