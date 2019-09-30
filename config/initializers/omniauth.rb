# frozen_string_literal: true

OmniAuth.config.logger = Rails.logger

HOST_CONSTRAINT_SETUP = lambda do |env|
  req = Rack::Request.new(env)
  if req.host != Rails.configuration.x.domains.app
    raise ActionController::RoutingError, "Not Found"
  end
end

# This is the omniauth config that the *users* of superpro might interact with
# To OAuth against say Google's services for Superpro to extract data from google, they'd oauth here.
# There's other auth mechanisms for the app, including another Omniauth instance using google_oauth2 config, but for the admin system, that only Superpro employees might use.
Rails.application.config.middleware.use OmniAuth::Builder do
  options path_prefix: "/connection_auth"

  provider :google_oauth2, Rails.configuration.google[:google_oauth_client_id], Rails.configuration.google[:google_oauth_client_secret], name: "google_analytics_oauth", scope: "analytics.readonly", access_type: "offline", prompt: "consent", include_granted_scopes: "true", setup: HOST_CONSTRAINT_SETUP

  provider :shopify, Rails.configuration.shopify[:api_key], Rails.configuration.shopify[:api_secret_key], :scope => "read_analytics,read_assigned_fulfillment_orders,read_content,read_customers,read_discounts,read_draft_orders,read_fulfillments,read_gift_cards,read_inventory,read_locations,read_marketing_events,read_merchant_managed_fulfillment_orders,read_online_store_pages,read_order_edits,read_orders,read_all_orders,read_price_rules,read_product_listings,read_products,write_script_tags,read_shipping,read_third_party_fulfillment_orders"

  provider :facebook, Rails.configuration.facebook[:app_id], Rails.configuration.facebook[:app_secret], scope: "ads_read,read_insights"
end
