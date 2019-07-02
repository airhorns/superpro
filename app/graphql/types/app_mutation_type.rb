class Types::AppMutationType < Types::BaseObject
  field :update_budget, mutation: Mutations::Budget::UpdateBudget
  field :create_process_template, mutation: Mutations::Todos::CreateProcessTemplate
  field :update_process_template, mutation: Mutations::Todos::UpdateProcessTemplate
  field :discard_process_template, mutation: Mutations::Todos::DiscardProcessTemplate
  field :create_process_execution, mutation: Mutations::Todos::CreateProcessExecution
  field :update_process_execution, mutation: Mutations::Todos::UpdateProcessExecution
end
