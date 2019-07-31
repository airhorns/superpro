module Types::Connections::ConnectionsQueries
  extend ActiveSupport::Concern

  included do
    field :plaid_items, Types::Connections::PlaidItemType.connection_type, null: false, description: "Get all the Plaid connections for the current account"

    field :shopify_shops, Types::Connections::ShopifyShopType.connection_type, null: false, description: "Get all the Shopify Shop connections for the current account"
  end

  def plaid_items
    context[:current_account].plaid_items
  end

  def shopify_shops
    context[:current_account].shopify_shops
  end
end
