# frozen_string_literal: true

class Sales::CustomerParetoFacts < DataModel::FactTable
  self.table = "warehouse.fct_shopify_customer_pareto"

  measure :sales, DataModel::Types::Currency, default_operator: false
  measure :customer_rank, DataModel::Types::Number, default_operator: false
  measure :percent_of_sales, DataModel::Types::Number, default_operator: false
  measure :cumulative_percent_of_sales, DataModel::Types::Number, default_operator: false

  dimension :customer_rank, DataModel::Types::Number
  dimension :customer_id, DataModel::Types::DateTime
  dimension :year, DataModel::Types::String

  dimension_join :customer, Sales::CustomersDimension
  dimension_join :business_line, Sales::BusinessLinesDimension
end
