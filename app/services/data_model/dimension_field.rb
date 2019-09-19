# frozen_string_literal: true

class DataModel::DimensionField
  attr_reader :field_name, :data_type, :custom_sql_node

  def initialize(field_name, data_type, sql: nil)
    @field_name = field_name
    @data_type = data_type
    @custom_sql_node = sql
  end
end
