# frozen_string_literal: true

class DataModel::Operator
  attr_reader :key, :valid_on_types, :valid_on_predicates

  def initialize(key, valid_on: nil, output_type: nil, &block)
    @key = key
    @valid_on_predicates, @valid_on_types = Array.wrap(valid_on).partition { |item| item.is_a?(Symbol) }
    @output_type = output_type
    @apply = block
  end

  def valid_on_type?(data_type)
    # If there's no validity conditions, it's always valid
    if @valid_on_types.empty? && @valid_on_predicates.empty?
      return true
    end

    return true if @valid_on_types.include?(data_type)
    return true if @valid_on_predicates.any? { |predicate| data_type.send(predicate) }

    false
  end

  def output_type(input_field)
    @output_type || input_field.data_type
  end

  def apply(expression)
    @apply.call(expression)
  end
end
