# frozen_string_literal: true

class Sales::CustomersDimension < DataModel::DimensionTable
  self.table = "warehouse.dim_shopify_customers"
  self.primary_key = :customer_id

  dimension :first_name, DataModel::Types::String
  dimension :last_name, DataModel::Types::String
  dimension :tax_exempt, DataModel::Types::Boolean
  dimension :accepts_marketing, DataModel::Types::Boolean

  dimension :created_at, DataModel::Types::DateTime
  dimension :first_order_at, DataModel::Types::DateTime
  dimension :most_recent_order_at, DataModel::Types::DateTime

  dimension :total_revenue, DataModel::Types::Currency
  dimension :total_order_count, DataModel::Types::Number
  dimension :total_successful_order_count, DataModel::Types::Number
  dimension :total_cancelled_order_count, DataModel::Types::Number
  dimension :previous_1_month_revenue, DataModel::Types::Currency
  dimension :previous_3_month_revenue, DataModel::Types::Currency
  dimension :previous_6_month_revenue, DataModel::Types::Currency
  dimension :previous_12_month_revenue, DataModel::Types::Currency

  dimension :future_3_month_predicted_revenue, DataModel::Types::Currency
  dimension :future_3_month_predicted_revenue_quintile, DataModel::Types::Number
  dimension :future_12_month_predicted_revenue, DataModel::Types::Currency
  dimension :future_12_month_predicted_revenue_quintile, DataModel::Types::Number
  dimension :future_24_month_predicted_revenue, DataModel::Types::Currency
  dimension :future_24_month_predicted_revenue_quintile, DataModel::Types::Number

  dimension :rfm_score, DataModel::Types::String
  dimension :rfm_label, DataModel::Types::String
  dimension :rfm_value_label, DataModel::Types::String
  dimension :rfm_recency_quintile, DataModel::Types::Number
  dimension :rfm_frequency_quintile, DataModel::Types::Number
  dimension :rfm_monetary_quintile, DataModel::Types::Number
end
