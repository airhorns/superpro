# frozen_string_literal: true

class Types::RecurrenceRuleString < GraphQL::Types::String
  def self.coerce_input(input_value, context)
    str = super(input_value, context)
    if str.is_a?(::String)
      str.gsub(/\ARRULE:/, "")
    else
      str
    end
  end

  def self.coerce_result(ruby_value, context)
    value = super(ruby_value, context)
    if value.is_a?(::String)
      "RRULE:" + value.to_s
    else
      value
    end
  end
end
