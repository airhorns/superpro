class Types::Budget::BudgetLineSeriesCellAttributes < Types::BaseInputObject
  argument :date_time, GraphQL::Types::ISO8601DateTime, required: false
  argument :amount_scenarios, Types::JSONScalar, required: false
end
