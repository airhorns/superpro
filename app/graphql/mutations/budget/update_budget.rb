class Mutations::Budget::UpdateBudget < Mutations::BaseMutation
  argument :id, GraphQL::Types::ID, required: true
  argument :attributes, Types::Budget::BudgetAttributes, required: true

  field :budget, Types::Budget::BudgetType, null: true
  field :errors, [Types::MutationErrorType], null: true

  def resolve(id:, attributes:)
    budget = context[:current_account].budgets.kept.includes(:budget_lines => [:account, :creator, :series, { :fixed_budget_line_descriptor => :budget_line_scenarios }]).find(id)
    result, errors = ::UpdateBudget.new(context[:current_user]).update(budget, attributes.to_h)

    { budget: result, errors: Types::MutationErrorType.format_errors_object(errors) }
  end
end
