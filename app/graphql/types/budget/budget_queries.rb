module Types::Budget::BudgetQueries
  extend ActiveSupport::Concern

  included do
    field :budgets, Types::Budget::BudgetType.connection_type, null: false, description: "Fetch all budgets in the system"
    field :budget, Types::Budget::BudgetType, null: true do
      description "Find a budget by ID"
      argument :id, GraphQL::Types::ID, required: true
    end

    field :default_budget, Types::Budget::BudgetType, null: false, description: "Get the default budget premade for all accounts"
  end

  def budgets
    context[:current_account].budgets.kept.all
  end

  def default_budget
    context[:current_account].budgets.kept.first
  end

  def budget(id:)
    context[:current_account].budgets.kept.find_by(id: id)
  end
end
