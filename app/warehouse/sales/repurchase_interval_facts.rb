# frozen_string_literal: true

class Sales::RepurchaseIntervalFacts < DataModel::FactTable
  self.table = "warehouse.fct_shopify_repurchase_intervals"

  measure :repeat_purchase_total_price, DataModel::Types::Currency
  measure :days_since_previous_order, DataModel::Types::Number

  dimension :order_date, DataModel::Types::DateTime
  dimension :previous_order_date, DataModel::Types::DateTime
  dimension :days_since_previous_order_bucket, DataModel::Types::Number
  dimension :days_since_previous_order_bucket_label, DataModel::Types::String

  dimension_join :customer, Sales::CustomersDimension
end
