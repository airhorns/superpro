# frozen_string_literal: true

class DataModel::DimensionField
  attr_reader :column_name, :data_type, :custom_sql_node

  def initialize(column_name, data_type, sql: nil)
    @column_name = column_name
    @data_type = data_type
    @custom_sql_node = sql
  end
end
