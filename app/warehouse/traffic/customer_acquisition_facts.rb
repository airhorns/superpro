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
  measure :future_12_month_predicted_spend, DataModel::Types::Currency
  measure :future_24_month_predicted_spend, DataModel::Types::Currency

  measure :days_until_next_order, DataModel::Types::Number

  measure :early_repurchaser_count, DataModel::Types::Number, allow_operators: false do
    Arel.sql("case when #{sql_string(table_node[:early_repurchaser].eq(true))} then 1 end").count
  end

  measure :early_repurchase_rate, DataModel::Types::Percentage, allow_operators: false do
    cast(
      Arel.sql("case when #{sql_string(table_node[:early_repurchaser].eq(true))} then 1 end").count,
      :numeric
    ) / nullif(Arel.sql("*").count, Arel.sql("0"))
  end

  measure :overall_repurchaser_count, DataModel::Types::Number, allow_operators: false do
    Arel.sql("case when #{sql_string(table_node[:total_successful_order_count].gt(1))} then 1 end").count
  end

  measure :overall_repurchase_rate, DataModel::Types::Percentage, allow_operators: false do
    cast(
      Arel.sql("case when #{sql_string(table_node[:total_successful_order_count].gt(1))} then 1 end").count,
      :numeric
    ) / nullif(Arel.sql("*").count, Arel.sql("0"))
  end

  dimension :acquired_at, DataModel::Types::DateTime
  dimension :early_repurchaser, DataModel::Types::Boolean
  dimension :landing_page_utm_source, DataModel::Types::String
  dimension :landing_page_utm_medium, DataModel::Types::String
  dimension :landing_page_utm_campaign, DataModel::Types::String
  dimension :landing_page_utm_content, DataModel::Types::String
  dimension :landing_page_source_category, DataModel::Types::String

  dimension :future_3_month_predicted_spend_quintile, DataModel::Types::Number
  dimension :future_12_month_predicted_spend_quintile, DataModel::Types::Number
  dimension :future_24_month_predicted_spend_quintile, DataModel::Types::Number
  dimension :future_3_month_predicted_spend_bucket_label, DataModel::Types::String
  dimension :future_12_month_predicted_spend_bucket_label, DataModel::Types::String
  dimension :future_24_month_predicted_spend_bucket_label, DataModel::Types::String

  dimension :landing_page_source_campaign, DataModel::Types::String do
    concat(table_node[:landing_page_utm_source], Arel.sql("' '"), table_node[:landing_page_utm_campaign])
  end

  dimension :landing_page_source_medium, DataModel::Types::String do
    concat(table_node[:landing_page_utm_source], Arel.sql("' '"), table_node[:landing_page_utm_medium])
  end

  dimension_join :customer, Sales::CustomersDimension
  dimension_join :business_line, Sales::BusinessLinesDimension

  global_filter :date, :acquired_at
  global_filter :business_line_id, :business_line_id
end
