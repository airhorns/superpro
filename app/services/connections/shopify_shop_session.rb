module Connections::ShopifyShopSession
  def self.with_session(api_key, password, domain)
    shop_url = "https://#{api_key}:#{password}@#{domain}"
    ShopifyAPI::Base.site = shop_url
    ShopifyAPI::Base.api_version = "2019-04"

    begin
      yield
    ensure
      ShopifyAPI::Base.site = nil
      ShopifyAPI::Base.api_version = nil
    end
  end

  def self.with_shop(shop, &block)
    with_session(shop.api_key, shop.password, shop.shopify_domain, &block)
  end
end
