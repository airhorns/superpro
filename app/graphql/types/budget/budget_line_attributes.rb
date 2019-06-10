class Types::Budget::BudgetLineAttributes < Types::BaseObject
  argument :description, String, required: true
  argument :section, String, required: true
  argument :recurrence_rules, [Types::RecurrenceRuleString], required: true
  argument :sort_order, Integer, required: true
  argument :scenarios, JSONScalar, required: true
end
