# frozen_string_literal: true

class Meta::ShopifyShopFacts < DataModel::FactTable
  self.table = "shopify_shops"
  dimension :id, DataModel::Types::String
  dimension :shop_id, DataModel::Types::String
  dimension :name, DataModel::Types::String
  dimension :shopify_domain, DataModel::Types::String
end
