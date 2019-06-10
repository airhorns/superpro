class Types::Budget::BudgetLineAttributes < Types::BaseInputObject
  argument :id, ID, required: true
  argument :description, String, required: true
  argument :section, String, required: true
  argument :recurrence_rules, [Types::RecurrenceRuleString], required: true
  argument :sort_order, Integer, required: true
  argument :amount_scenarios, Types::JSONScalar, required: true
end
