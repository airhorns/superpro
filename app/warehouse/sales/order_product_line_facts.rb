# frozen_string_literal: true

class Sales::OrderProductLineFacts < DataModel::FactTable
  self.table = "warehouse.fct_shopify_order_product_lines"

  measure :pre_tax_price, DataModel::Types::Currency
  measure :price, DataModel::Types::Currency
  measure :quantity, DataModel::Types::Number

  dimension :created_at, DataModel::Types::DateTime, label: "Order Date"
  dimension :new_vs_repeat, DataModel::Types::String

  dimension :taxable, DataModel::Types::Boolean
  dimension :new_vs_repeat, DataModel::Types::String
  dimension :order_seq_number, DataModel::Types::String

  dimension_join :customer, Sales::CustomersDimension
  dimension_join :business_line, Sales::BusinessLinesDimension
  dimension_join :variant, Merchandise::VariantsDimension

  global_filter :date, :created_at
  global_filter :business_line_id, :business_line_id
end
