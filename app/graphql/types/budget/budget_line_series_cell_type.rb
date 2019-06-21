class Types::Budget::BudgetLineSeriesCellType < Types::BaseObject
  field :date_time, GraphQL::Types::ISO8601DateTime, null: false
  field :amount_scenarios, Types::JSONScalar, null: false
end
