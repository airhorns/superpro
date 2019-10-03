# frozen_string_literal: true

class DataModel::DimensionField
  attr_reader :field_name, :field_label, :data_type, :column_name, :custom_sql_node, :join

  def initialize(field_name, data_type, sql: nil, column: nil, label: nil, join: nil)
    @field_name = field_name
    @column_name = column || field_name
    @field_label = label || field_name.to_s.titleize
    @data_type = data_type
    @custom_sql_node = sql
    @join = join
  end

  def allows_operators?
    true
  end

  def requires_join?
    @join.present?
  end
end
