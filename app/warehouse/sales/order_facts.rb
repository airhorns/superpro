# frozen_string_literal: true

class Sales::OrderFacts < DataModel::FactTable
  self.table = "warehouse.fct_shopify_orders"

  measure :total_price, DataModel::Types::Currency
  measure :total_weight, DataModel::Types::Weight

  dimension :created_at, DataModel::Types::DateTime
  dimension :processed_at, DataModel::Types::DateTime
  dimension :closed_at, DataModel::Types::DateTime
  dimension :cancelled_at, DataModel::Types::DateTime
  dimension :cancelled, DataModel::Types::Boolean

  dimension :new_vs_repeat, DataModel::Types::String

  dimension_join :customer, Sales::CustomersDimension
end
