# frozen_string_literal: true

class DataModel::DimensionField
  attr_reader :field_name, :field_label, :data_type, :custom_sql_node

  def initialize(field_name, data_type, sql: nil, label: nil)
    @field_name = field_name
    @field_label = label || field_name.to_s.titleize
    @data_type = data_type
    @custom_sql_node = sql
  end

  def allows_operators?
    true
  end
end
