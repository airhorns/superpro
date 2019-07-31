class Connections::ConnectShopify
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

    with_session(api_key, password, domain) do
      begin
        shop_response = ShopifyAPI::Shop.current
      rescue StandardError => e
        Rails.logger.warn(e.message)
        return nil, ["There was an error connecting Shopify. Please check your credentials and try again."]
      end

      shop = @account.shopify_shops.find_or_initialize_by(shop_id: shop_response.id)

      ShopifyShop.transaction do
        shop.creator ||= @user
        shop.api_key = api_key
        shop.password = password
        shop.shopify_domain = shop_response.myshopify_domain
        shop.name = shop_response.name

        shop.save!

        connection = @account.connections.find_or_initialize_by(integration: shop)
        connection.display_name = "Shopify Shop #{shop.name} (Shop ID: #{shop_response.id})"
        connection.save!
      end

      if shop.persisted?
        return shop, nil
      else
        return nil, ["There was an error saving your Shopify shop. PLease try again."]
      end
    end
  end

  def with_session(api_key, password, domain)
    shop_url = "https://#{api_key}:#{password}@#{domain}"
    ShopifyAPI::Base.site = shop_url
    ShopifyAPI::Base.api_version = "2019-04"

    begin
      yield
    rescue
      ShopifyAPI::Base.site = nil
      ShopifyAPI::Base.api_version = nil
    end
  end
end
