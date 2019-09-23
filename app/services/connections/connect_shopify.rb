# frozen_string_literal: true

module Connections
  class ConnectShopify
    VALID_SHOPIFY_DOMAIN_SUFFIX = "myshopify.com"

    def initialize(account, user)
      @account = account
      @user = user
    end

    def connect_using_auth_hash(auth_hash)
      domain = auth_hash[:uid]
      access_token = auth_hash[:credentials][:token]
      ShopifyShopSession.with_oauth_app_session(access_token, domain) do
        connect do |shop|
          shop.access_token = access_token
        end
      end
    end

    def connect_private_app(api_key, password, domain)
      domain = domain.strip
      if !domain.end_with?(VALID_SHOPIFY_DOMAIN_SUFFIX)
        return nil, ["There was an error connecting Shopify. Please ensure your domain is your canonical <something>.myshopify.com domain."]
      end

      ShopifyShopSession.with_private_app_session(api_key, password, domain) do
        connect do |shop|
          shop.api_key = api_key
          shop.password = password
        end
      end
    end

    private

    def connect
      begin
        shop = shop_for_save
      rescue StandardError => e
        Rails.logger.warn(e.message)
        return nil, ["There was an error connecting Shopify. Please check your credentials and try again."]
      end

      yield shop
      connection = connection_for_save(shop)

      ShopifyShop.transaction do
        shop.save!
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

    def shop_for_save
      shop_response = ShopifyAPI::Shop.current
      shop = @account.shopify_shops.find_or_initialize_by(shop_id: shop_response.id)
      shop.shopify_domain = shop_response.myshopify_domain
      shop.name = shop_response.name
      shop.creator ||= @user
      shop
    end

    def connection_for_save(shop)
      connection = @account.connections.kept.find_or_initialize_by(integration: shop)
      connection.strategy = "singer"
      connection.display_name = "Shopify Shop #{shop.name} (Shop ID: #{shop.shop_id})"
      connection
    end
  end
end
