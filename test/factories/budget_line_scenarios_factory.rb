FactoryBot.define do
  factory :budget_line_scenario do
    association :account
    association :budget_line
    scenario { "default" }
    currency { "USD" }
    amount_subunits { 100 }
  end
end
