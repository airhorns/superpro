# frozen_string_literal: true

module Connections::ShopifyShopSession
  API_VERSION = "2019-04"

  def self.with_private_app_session(api_key, password, domain)
    shop_url = "https://#{api_key}:#{password}@#{domain}"
    ShopifyAPI::Base.site = shop_url
    ShopifyAPI::Base.api_version = API_VERSION
    begin
      yield
    ensure
      ShopifyAPI::Base.clear_session
    end
  end

  def self.with_oauth_app_session(access_token, domain, &block)
    ShopifyAPI::Session.temp(domain: domain, token: access_token, api_version: API_VERSION, &block)
  end

  def self.with_shop(shop, &block)
    if shop.access_token
      with_oauth_app_session(shop.access_token, shop.shopify_domain, &block)
    else
      with_private_app_session(shop.api_key, shop.password, shop.shopify_domain, &block)
    end
  end
end
