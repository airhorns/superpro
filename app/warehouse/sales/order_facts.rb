# frozen_string_literal: true

class Sales::OrderFacts < DataModel::FactTable
  self.table = "warehouse.fct_shopify_orders"

  measure :total_price, DataModel::Types::Currency
  measure :total_weight, DataModel::Types::Weight

  measure :unique_customer_count, DataModel::Types::Number, sql: table_node[:customer_id].count(true), allow_operators: false
  measure :order_count, DataModel::Types::Number, sql: table_node[:order_id].count(true), allow_operators: false
  measure :orders_per_customer, DataModel::Types::Number, allow_operators: false do
    cast(table_node[:order_id].count(true), :numeric) / nullif(table_node[:customer_id].count(true), Arel.sql("0"))
  end

  dimension :created_at, DataModel::Types::DateTime, label: "Order Date"
  dimension :processed_at, DataModel::Types::DateTime
  dimension :closed_at, DataModel::Types::DateTime
  dimension :cancelled_at, DataModel::Types::DateTime
  dimension :cancelled, DataModel::Types::Boolean
  dimension :customer_id, DataModel::Types::String
  dimension :order_id, DataModel::Types::String
  dimension :landing_page_utm_medium, DataModel::Types::String
  dimension :landing_page_utm_source, DataModel::Types::String
  dimension :landing_page_utm_campaign, DataModel::Types::String
  dimension :landing_page_utm_content, DataModel::Types::String

  dimension :new_vs_repeat, DataModel::Types::String

  dimension_join :customer, Sales::CustomersDimension
  dimension_join :business_line, Sales::BusinessLinesDimension

  global_filter :date, :created_at
  global_filter :business_line_id, :business_line_id
end
