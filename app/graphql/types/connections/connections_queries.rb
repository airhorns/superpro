module Types::Connections::ConnectionsQueries
  extend ActiveSupport::Concern

  included do
    field :plaid_items, Types::Connections::PlaidItemType.connection_type, null: false, description: "Get all the Plaid connections for the current account"

    field :shopify_shops, Types::Connections::ShopifyShopType.connection_type, null: false, description: "Get all the Shopify Shop connections for the current account"

    field :connections, Types::Connections::ConnectionType.connection_type, null: false, description: "Get all the connections for all integrations for the current account"

    field :google_analytics_views, Types::Connections::GoogleAnalyticsViewType.connection_type, null: false, description: "Get all the google analytics views for a given credential" do
      argument :credential_id, GraphQL::Types::ID, required: true
    end

    field :google_analytics_credentials, Types::Connections::GoogleAnalyticsCredentialType.connection_type, null: false, description: "Get all the Google Analytics accounts configured for the current account"
  end

  def plaid_items
    context[:current_account].plaid_items
  end

  def shopify_shops
    context[:current_account].shopify_shops
  end

  def connections
    context[:current_account].connections
  end

  def google_analytics_views(credential_id:)
    credential = context[:current_account].google_analytics_credentials.find(credential_id)
    Connections::ConnectGoogleAnalytics.new(context[:current_account], context[:current_account]).list_views(credential)
  end

  def google_analytics_credentials
    context[:current_account].google_analytics_credentials.where(configured: true)
  end
end
