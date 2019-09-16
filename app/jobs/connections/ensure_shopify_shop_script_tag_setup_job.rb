class Connections::EnsureShopifyShopScriptTagSetupJob < Que::Job
  def run(shopify_shop_id:)
    shop = ShopifyShop.find(shopify_shop_id)
    Connections::ShopifyScriptTagManager.ensure_shop_setup(shop)
  end
end
