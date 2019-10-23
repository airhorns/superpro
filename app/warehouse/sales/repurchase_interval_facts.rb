# frozen_string_literal: true

class Sales::RepurchaseIntervalFacts < DataModel::FactTable
  self.table = "warehouse.fct_shopify_repurchase_intervals"

  measure :total_price, DataModel::Types::Currency
  measure :days_since_previous_order, DataModel::Types::Number
  measure :days_until_next_order, DataModel::Types::Number
  measure :early_repurchase_rate, DataModel::Types::Percentage, allow_operators: false do
    cast(
      Arel.sql("case when #{sql_string(table_node[:order_seq_number].eq(1))} and #{sql_string(table_node[:days_until_next_order].lteq(60))} then 1 end").count,
      :numeric
    ) / nullif(Arel.sql("*").count, Arel.sql("0"))
  end
  measure :overall_repurchase_rate, DataModel::Types::Percentage, allow_operators: false do
    cast(
      Arel.sql("case when #{sql_string(table_node[:order_seq_number].eq(1))} and #{sql_string(table_node[:days_until_next_order].not_eq(nil))} then 1 end").count,
      :numeric
    ) / nullif(Arel.sql("*").count, Arel.sql("0"))
  end

  dimension :order_date, DataModel::Types::DateTime
  dimension :order_seq_number, DataModel::Types::Number
  dimension :previous_order_date, DataModel::Types::DateTime
  dimension :next_order_date, DataModel::Types::DateTime
  dimension :days_since_previous_order_bucket, DataModel::Types::Number
  dimension :days_since_previous_order_bucket_label, DataModel::Types::String
  dimension :days_until_next_order_bucket, DataModel::Types::Number
  dimension :days_until_next_order_bucket_label, DataModel::Types::String

  dimension_join :customer, Sales::CustomersDimension

  global_filter :date, :order_date
end
