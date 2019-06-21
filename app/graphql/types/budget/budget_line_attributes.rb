class Types::Budget::BudgetLineAttributes < Types::BaseInputObject
  argument :id, ID, required: true
  argument :description, String, required: true
  argument :section, String, required: true
  argument :sort_order, Integer, required: true
  argument :value, Types::Budget::BudgetLineValueAttributes, required: true
end
