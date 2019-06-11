class Types::Budget::BudgetLineType < Types::BaseObject
  field :id, GraphQL::Types::ID, null: false

  field :amount, Types::MoneyType, null: false
  field :description, String, null: false
  field :section, String, null: false
  field :occurs_at, GraphQL::Types::ISO8601DateTime, null: false
  field :recurrence_rules, [Types::RecurrenceRuleString], null: true
  field :sort_order, Integer, null: false
  field :amount_scenarios, Types::JSONScalar, null: false

  field :creator, Types::Identity::UserType, null: false
  field :budget, Types::Budget::BudgetType, null: false

  field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  field :discarded_at, GraphQL::Types::ISO8601DateTime, null: false

  def amount_scenarios
    AssociationLoader.for(BudgetLine, :budget_line_scenarios).load(object).then do |scenarios|
      scenarios.each_with_object({}) do |scenario, agg|
        agg[scenario.scenario] = scenario.amount.fractional
      end
    end
  end
end
