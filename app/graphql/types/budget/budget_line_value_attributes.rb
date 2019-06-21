class Types::Budget::BudgetLineValueAttributes < Types::BaseInputObject
  # This is a user-land union of the different types of values a budget line can hold because GraphQL doesn't support union
  # input types. The code consuming these attributes looks at the type argument and works with different properties depending
  # on which type is at play.
  argument :type, String, required: true
  argument :occurs_at, GraphQL::Types::ISO8601DateTime, required: false
  argument :recurrence_rules, [Types::RecurrenceRuleString], required: false
  argument :amount_scenarios, Types::JSONScalar, required: false
  argument :cells, [Types::Budget::BudgetLineSeriesCellAttributes], required: false
end
