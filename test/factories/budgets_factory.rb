FactoryBot.define do
  factory :budget do
    association :account
    association :creator, factory: :user
    name { "Test Budget" }

    factory :base_operational_budget do
      name { "Operational Budget" }

      after(:create) do |budget|
        budget.budget_lines = build_list(:budget_line, 4, budget: budget, account: budget.account, creator: budget.creator, amount_subunits: 2000) + build_list(:budget_line, 4, budget: budget, account: budget.account, creator: budget.creator, amount_subunits: -2000)
        budget.save!
      end
    end
  end
end
