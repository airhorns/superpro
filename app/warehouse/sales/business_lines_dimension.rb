# frozen_string_literal: true

class Sales::BusinessLinesDimension < DataModel::DimensionTable
  self.table = "warehouse.dim_business_lines"
  self.primary_key = :business_line_id

  dimension :name, DataModel::Types::String
end
