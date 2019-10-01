# frozen_string_literal: true

class Sales::RepurchaseCohortFacts < DataModel::FactTable
  self.table = "warehouse.fct_shopify_customer_retention"

  measure :total_customers, DataModel::Types::Number, default_operator: false
  measure :total_active_customers, DataModel::Types::Number, default_operator: false
  measure :total_orders, DataModel::Types::Number, default_operator: false
  measure :total_spend, DataModel::Types::Currency, default_operator: false
  measure :pct_active_customers, DataModel::Types::Number, default_operator: false
  measure :months_since_genesis, DataModel::Types::Number, default_operator: false
  measure :genesis_month, DataModel::Types::DateTime, default_operator: false
end
