# frozen_string_literal: true

class Customers::RFMThresholdFacts < DataModel::FactTable
  self.table = "warehouse.fct_shopify_rfm_thresholds"

  measure :monetary_threshold, DataModel::Types::Currency, default_operator: :average
  measure :recency_threshold, DataModel::Types::Number, default_operator: :average
  measure :frequency_threshold, DataModel::Types::Number, default_operator: :average

  dimension :recency_quintile, DataModel::Types::Number
  dimension :frequency_quintile, DataModel::Types::Number
  dimension :monetary_quintile, DataModel::Types::Number

  dimension_join :business_line, Sales::BusinessLinesDimension
end
