module Connections
  class ConnectShopify
    VALID_SHOPIFY_DOMAIN_SUFFIX = "myshopify.com"

    def initialize(account, user)
      @account = account
      @user = user
    end

    def connect_private_app(api_key, password, domain)
      domain = domain.strip
      if !domain.end_with?(VALID_SHOPIFY_DOMAIN_SUFFIX)
        return nil, ["There was an error connecting Shopify. Please ensure your domain is your canonical <something>.myshopify.com domain."]
      end

      ShopifyShopSession.with_session(api_key, password, domain) do
        begin
          shop_response = ShopifyAPI::Shop.current
        rescue StandardError => e
          Rails.logger.warn(e.message)
          return nil, ["There was an error connecting Shopify. Please check your credentials and try again."]
        end

        shop = @account.shopify_shops.find_or_initialize_by(shop_id: shop_response.id)
        connection = nil

        ShopifyShop.transaction do
          shop.creator ||= @user
          shop.api_key = api_key
          shop.password = password
          shop.shopify_domain = shop_response.myshopify_domain
          shop.name = shop_response.name

          shop.save!

          connection = @account.connections.kept.find_or_initialize_by(integration: shop)
          connection.strategy = "singer"
          connection.display_name = "Shopify Shop #{shop.name} (Shop ID: #{shop_response.id})"
          connection.save!
        end

        if shop.persisted? && connection && connection.persisted?
          Infrastructure::SingerConnectionSync.run_in_background(connection)
          Connections::ShopifyScriptTagManager.ensure_connection_setup_in_background(connection)
          return shop, nil
        else
          return nil, ["There was an error saving your Shopify shop. PLease try again."]
        end
      end
    end
  end
end
