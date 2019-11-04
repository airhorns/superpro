# frozen_string_literal: true

class Merchandise::VariantsDimension < DataModel::DimensionTable
  self.table = "warehouse.dim_shopify_variants"
  self.primary_key = :variant_id

  dimension :variant_title, DataModel::Types::String
  dimension :product_title, DataModel::Types::String
  dimension :sku, DataModel::Types::String
  dimension :product_vendor, DataModel::Types::String
  dimension :product_type, DataModel::Types::String

  dimension :position, DataModel::Types::Number
  dimension :product_id, DataModel::Types::String

  dimension :variant_created_at, DataModel::Types::DateTime
  dimension :product_created_at, DataModel::Types::DateTime
  dimension :product_published_at, DataModel::Types::DateTime

  dimension :current_price, DataModel::Types::Currency
end
