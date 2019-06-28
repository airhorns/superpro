class Types::AppMutationType < Types::BaseObject
  field :update_budget, mutation: Mutations::Budget::UpdateBudget
  field :create_process_template, mutation: Mutations::Todos::CreateProcessTemplate
  field :update_process_template, mutation: Mutations::Todos::UpdateProcessTemplate
end
