class Types::Budget::BudgetProblemSpotType < Types::BaseObject
  field :spot_number, Integer, null: false
  field :scenario, String, null: false
  field :start_date, GraphQL::Types::ISO8601DateTime, null: false
  field :end_date, GraphQL::Types::ISO8601DateTime, null: false
  field :min_cash_on_hand, Types::MoneyType, null: false
end
