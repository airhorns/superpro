# frozen_string_literal: true

class Sales::OrderFacts < DataModel::FactTable
  self.table = "warehouse.fct_shopify_orders"

  measure :total_price, DataModel::Types::Currency
  measure :total_weight, DataModel::Types::Weight

  measure :customer_count, DataModel::Types::Number, sql: table_node[:customer_id].count(true), allow_operators: false
  measure :order_count, DataModel::Types::Number, sql: table_node[:order_id].count(true), allow_operators: false
  measure :orders_per_customer, DataModel::Types::Number, sql: (table_node[:order_id].count(true) / table_node[:customer_id].count(true)), allow_operators: false

  dimension :created_at, DataModel::Types::DateTime
  dimension :processed_at, DataModel::Types::DateTime
  dimension :closed_at, DataModel::Types::DateTime
  dimension :cancelled_at, DataModel::Types::DateTime
  dimension :cancelled, DataModel::Types::Boolean
  dimension :customer_id, DataModel::Types::String
  dimension :order_id, DataModel::Types::String

  dimension :new_vs_repeat, DataModel::Types::String

  dimension_join :customer, Sales::CustomersDimension
end
