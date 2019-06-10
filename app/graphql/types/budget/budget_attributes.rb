class Types::Budget::BudgetAttributes < Types::BaseObject
  description "Attributes for creating or updating a budget"
  argument :name, String, "Name to set on the budget", required: false
  argument :budget_lines, [Types::Budget::BudgetLineAttributes], required: true
end
