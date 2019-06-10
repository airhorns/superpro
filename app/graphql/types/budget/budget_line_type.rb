class Types::Budget::BudgetLineType < Types::BaseObject
  field :id, GraphQL::Types::ID, null: false

  field :variable, Boolean, null: false
  field :amount, Types::MoneyType, null: false
  field :description, String, null: false
  field :section, String, null: false
  field :recurrence_rules, [Types::RecurrenceRuleString], null: false
  field :sort_order, Integer, null: false

  field :creator, Types::Identity::UserType, null: false
  field :budget, Types::Budget::BudgetType, null: false

  field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  field :discarded_at, GraphQL::Types::ISO8601DateTime, null: false
end
