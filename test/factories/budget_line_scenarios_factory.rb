FactoryBot.define do
  factory :budget_line_scenario do
    association :account
    association :fixed_budget_line_descriptor
    scenario { "default" }
    currency { "USD" }
    amount_subunits { 100 }
  end
end
