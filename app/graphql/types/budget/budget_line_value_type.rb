class Types::Budget::BudgetLineValueType < Types::BaseUnion
  description "How the value over time of a budget line is expressed"
  possible_types Types::Budget::BudgetLineFixedValueType, Types::Budget::BudgetLineSeriesValueType

  # Optional: if this method is defined, it will override `Schema.resolve_type`
  def self.resolve_type(budget_line, _context)
    if budget_line.value_type_fixed?
      Types::Budget::BudgetLineFixedValueType
    else
      Types::Budget::BudgetLineSeriesValueType
    end
  end
end
