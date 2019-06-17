class Mutations::Budget::UpdateBudget < Mutations::BaseMutation
  argument :budget_id, GraphQL::Types::ID, required: true
  argument :budget, Types::Budget::BudgetAttributes, required: true

  field :budget, Types::Budget::BudgetType, null: true
  field :errors, [Types::MutationErrorType], null: true

  def resolve(budget_id:, budget:)
    existing_budget = context[:current_account].budgets.kept.includes(:budget_lines => [:series, :budget_line_scenarios]).find(budget_id)
    result, errors = ::UpdateBudget.new(context[:current_user]).update(existing_budget, budget.to_h)
    { budget: result, errors: Types::MutationErrorType.format_errors_object(errors) }
  end
end
