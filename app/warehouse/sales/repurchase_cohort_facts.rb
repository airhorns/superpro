# frozen_string_literal: true

class Sales::RepurchaseCohortFacts < DataModel::FactTable
  self.table = "warehouse.fct_shopify_customer_retention"

  measure :total_customers, DataModel::Types::Number
  measure :total_active_customers, DataModel::Types::Number
  measure :total_orders, DataModel::Types::Number
  measure :total_spend, DataModel::Types::Currency
  measure :pct_active_customers, DataModel::Types::Number
  measure :months_since_genesis, DataModel::Types::Number
  measure :genesis_month, DataModel::Types::DateTime
end
