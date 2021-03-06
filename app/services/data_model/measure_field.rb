# frozen_string_literal: true

class DataModel::MeasureField
  attr_reader :field_name, :field_label, :column_name, :data_type, :default_operator, :custom_sql_node, :join

  def initialize(field_name, data_type, column: nil, default_operator: nil, allow_operators: true, require_operators: nil, sql: nil, label: nil, join: nil)
    if allow_operators == false && require_operators == true
      throw "Misconfigured MeasureField #{field_name}, you can't require operators if you don't allow them."
    end

    @field_name = field_name
    @field_label = label || field_name.to_s.titleize
    @column_name = column || field_name
    @data_type = data_type
    @join = join

    @allow_operators = allow_operators
    if @allow_operators
      @default_operator = if default_operator
                            default_operator
                          elsif default_operator.nil?
                            @data_type.default_operator
                          end

      @require_operators = !!require_operators
    else
      @require_operators = false
    end

    @custom_sql_node = sql || block_given? && yield
  end

  def allows_operators?
    @allow_operators
  end

  def requires_operators?
    @require_operators
  end

  def requires_join?
    @join.present?
  end
end
