# frozen_string_literal: true

class Sales::CustomersDimension < DataModel::DimensionTable
  self.table = "fct_shopify_orders"
  self.primary_key = :customer_id

  dimension :first_name, DataModel::Types::String
  dimension :last_name, DataModel::Types::String
  dimension :rfm_name, DataModel::Types::String
  dimension :tax_exempt, DataModel::Types::Boolean

  dimension :total_spend, DataModel::Types::Currency
  dimension :total_order_count, DataModel::Types::Number
  dimension :total_successful_order_count, DataModel::Types::Number
  dimension :total_cancelled_order_count, DataModel::Types::Number
end
