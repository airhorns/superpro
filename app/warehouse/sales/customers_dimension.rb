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
  dimension :total_order_count, DataModel::Types::Number, measureable: true
  dimension :total_successful_order_count, DataModel::Types::Number, measureable: true
  dimension :total_cancelled_order_count, DataModel::Types::Number, measureable: true
  dimension :previous_1_month_revenue, DataModel::Types::Currency, measureable: true
  dimension :previous_3_month_revenue, DataModel::Types::Currency, measureable: true
  dimension :previous_6_month_revenue, DataModel::Types::Currency, measureable: true
  dimension :previous_12_month_revenue, DataModel::Types::Currency, measureable: true

  dimension :future_3_month_predicted_revenue, DataModel::Types::Currency, measureable: true
  dimension :future_3_month_predicted_revenue_quintile, DataModel::Types::Number
  dimension :future_12_month_predicted_revenue, DataModel::Types::Currency, measureable: true
  dimension :future_12_month_predicted_revenue_quintile, DataModel::Types::Number
  dimension :future_24_month_predicted_revenue, DataModel::Types::Currency, measureable: true
  dimension :future_24_month_predicted_revenue_quintile, DataModel::Types::Number

  dimension :rfm_score, DataModel::Types::String
  dimension :rfm_label, DataModel::Types::String
  dimension :rfm_value_label, DataModel::Types::String
  dimension :rfm_recency_quintile, DataModel::Types::Number
  dimension :rfm_frequency_quintile, DataModel::Types::Number
  dimension :rfm_monetary_quintile, DataModel::Types::Number

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
    Arel.sql("case when #{sql_string(table_node[:ever_repurchaser])} then 1 end").count
  end

  measure :overall_repurchase_rate, DataModel::Types::Percentage, allow_operators: false do
    cast(
      Arel.sql("case when #{sql_string(table_node[:ever_repurchaser])} then 1 end").count,
      :numeric
    ) / nullif(Arel.sql("*").count, Arel.sql("0"))
  end
end
