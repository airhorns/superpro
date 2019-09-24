# frozen_string_literal: true

class DataModel::MeasureField
  MEASURE_OPERATORS = Set.new(%i[ sum count count_distinct min max average ])

  attr_reader :field_name, :field_label, :data_type, :default_operator, :allow_operator, :custom_sql_node

  def initialize(field_name, data_type, default_operator: nil, except_operators: nil, allow_operators: true, sql: nil, label: nil)
    @field_name = field_name
    @field_label = label || field_name.to_s.titleize
    @data_type = data_type

    @default_operator = default_operator || :sum
    @valid_operators = MEASURE_OPERATORS - Set.new(except_operators || [])
    @allow_operators = allow_operators
    @custom_sql_node = sql
  end

  def allows_operators?
    @allow_operators || true
  end
end
