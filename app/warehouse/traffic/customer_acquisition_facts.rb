# frozen_string_literal: true

class Traffic::CustomerAcquisitionFacts < DataModel::FactTable
  self.table = "warehouse.fct_customer_acquisitions"

  measure :first_order_total_price, DataModel::Types::Currency
  measure :total_order_count, DataModel::Types::Number
  measure :total_successful_order_count, DataModel::Types::Number
  measure :total_cancelled_order_count, DataModel::Types::Number
  measure :total_spend, DataModel::Types::Currency

  measure :previous_1_month_spend, DataModel::Types::Currency
  measure :previous_3_month_spend, DataModel::Types::Currency
  measure :previous_6_month_spend, DataModel::Types::Currency
  measure :previous_12_month_spend, DataModel::Types::Currency

  measure :future_3_month_predicted_spend, DataModel::Types::Currency
  measure :future_3_month_predicted_spend_quintile, DataModel::Types::Number
  measure :future_12_month_predicted_spend, DataModel::Types::Currency
  measure :future_12_month_predicted_spend_quintile, DataModel::Types::Number
  measure :future_24_month_predicted_spend, DataModel::Types::Currency
  measure :future_24_month_predicted_spend_quintile, DataModel::Types::Number

  measure :days_until_next_order, DataModel::Types::Number

  dimension :acquired_at, DataModel::Types::DateTime
  dimension :early_repurchaser, DataModel::Types::Boolean
  dimension :landing_page_utm_source, DataModel::Types::String
  dimension :landing_page_utm_medium, DataModel::Types::String
  dimension :landing_page_utm_campaign, DataModel::Types::String
  dimension :landing_page_utm_content, DataModel::Types::String

  dimension_join :customer, Sales::CustomersDimension
  dimension_join :business_line, Sales::BusinessLinesDimension

  global_filter :date, :acquired_at
  global_filter :business_line_id, :business_line_id
end
