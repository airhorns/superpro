# frozen_string_literal: true

class AddScriptTagSetupAtToShopifyShops < ActiveRecord::Migration[6.0]
  def change
    add_column :shopify_shops, :script_tag_setup_at, :timestamp
  end
end
