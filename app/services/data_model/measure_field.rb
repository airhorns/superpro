# frozen_string_literal: true

class DataModel::MeasureField
  MEASURE_OPERATORS = Set.new(%i[ sum count count_distinct min max average p80 p90 p95 ])

  attr_reader :field_name, :field_label, :data_type, :default_operator, :custom_sql_node

  def initialize(field_name, data_type, default_operator: nil, allow_operators: true, require_operators: nil, sql: nil, label: nil)
    if allow_operators == false && require_operators == true
      throw "Misconfigured MeasureField #{field_name}, you can't require operators if you don't allow them."
    end

    @field_name = field_name
    @field_label = label || field_name.to_s.titleize
    @data_type = data_type

    @default_operator = default_operator || :sum
    @allow_operators = allow_operators
    @require_operators = require_operators.nil? ? allow_operators : true  # operators are only required if they're allowed
    @custom_sql_node = sql || block_given? && yield
  end

  def allows_operators?
    @allow_operators
  end

  def requires_operators?
    @require_operators
  end
end
