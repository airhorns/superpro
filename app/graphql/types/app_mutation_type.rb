class Types::AppMutationType < Types::BaseObject
  field :update_budget, mutation: Mutations::Budget::UpdateBudget
end
