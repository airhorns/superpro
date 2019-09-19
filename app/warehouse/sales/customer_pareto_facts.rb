# frozen_string_literal: true

class Sales::CustomerParetoFacts < DataModel::FactTable
  self.table = "warehouse.fct_shopify_customer_pareto"

  measure :sales, DataModel::Types::Currency
  measure :customer_rank, DataModel::Types::Number
  measure :percent_of_sales, DataModel::Types::Number
  measure :cumulative_percent_of_sales, DataModel::Types::Number

  dimension :customer_rank, DataModel::Types::Number
  dimension :customer_id, DataModel::Types::DateTime
  dimension :year, DataModel::Types::String
  dimension_join :customer, Sales::CustomersDimension
end
