module Types::Budget::BudgetQueries
  extend ActiveSupport::Concern

  included do
    field :budgets, [Types::Budget::BudgetType], null: false, description: "Fetch all budgets in the system"
    field :budget, Types::Budget::BudgetType, null: true do
      description "Find a budget by ID"
      argument :budget_id, GraphQL::Types::ID, required: true
    end
  end

  def budgets
    context[:current_account].budgets.kept.all
  end

  def budget(budget_id:)
    context[:current_account].budgets.kept.find(budget_id)
  end
end
