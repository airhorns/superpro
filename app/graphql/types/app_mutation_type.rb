class Types::AppMutationType < Types::BaseObject
  # Budgets
  field :update_budget, mutation: Mutations::Budget::UpdateBudget

  # Todos
  field :create_process_template, mutation: Mutations::Todos::CreateProcessTemplate
  field :update_process_template, mutation: Mutations::Todos::UpdateProcessTemplate
  field :discard_process_template, mutation: Mutations::Todos::DiscardProcessTemplate
  field :create_process_execution, mutation: Mutations::Todos::CreateProcessExecution
  field :update_process_execution, mutation: Mutations::Todos::UpdateProcessExecution
  field :discard_process_execution, mutation: Mutations::Todos::DiscardProcessExecution
  field :create_scratchpad, mutation: Mutations::Todos::CreateScratchpad
  field :update_scratchpad, mutation: Mutations::Todos::UpdateScratchpad
end
