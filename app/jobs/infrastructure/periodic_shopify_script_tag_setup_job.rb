class Infrastructure::PeriodicShopifyScriptTagSetupJob < Que::Job
  def run
    Connection.kept.includes(:account).where(strategy: "singer", integration_type: "ShopifyShop", enabled: true).find_each do |connection|
      Connections::ShopifyScriptTagManager.ensure_connection_setup_in_background(connection)
    end
  end

  def log_level(_elapsed)
    :info
  end
end
