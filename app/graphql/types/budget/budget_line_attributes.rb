class Types::Budget::BudgetLineAttributes < Types::BaseInputObject
  argument :id, ID, required: true
  argument :description, String, required: true
  argument :section, String, required: true
  argument :occurs_at, GraphQL::Types::ISO8601DateTime, required: true
  argument :recurrence_rules, [Types::RecurrenceRuleString], required: false
  argument :sort_order, Integer, required: true
  argument :amount_scenarios, Types::JSONScalar, required: true
end
