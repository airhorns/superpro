# frozen_string_literal: true

class AddOAuthFieldsToShopifyShops < ActiveRecord::Migration[6.0]
  def change
    add_column :shopify_shops, :access_token, :string
    change_column_null :shopify_shops, :api_key, true
    change_column_null :shopify_shops, :password, true
  end
end
