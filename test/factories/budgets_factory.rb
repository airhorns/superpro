def apply_sort_orders(budget_lines)
  budget_lines.each_with_index do |line, index|
    line.sort_order = index
  end
end

FactoryBot.define do
  factory :budget do
    association :account
    association :creator, factory: :user
    name { "Test Budget" }

    factory :base_operational_budget do
      name { "Operational Budget" }

      after(:create) do |budget|
        facilities_lines = build_list(:budget_line, 4, section: "Facilities", budget: budget, account: budget.account, creator: budget.creator, amount_subunits: 2000) + build_list(:budget_line, 4, section: "Facilities", budget: budget, account: budget.account, creator: budget.creator, amount_subunits: -2000)
        apply_sort_orders(facilities_lines)

        materials_lines = build_list(:budget_line, 4, section: "Materials", budget: budget, account: budget.account, creator: budget.creator, amount_subunits: 2000) + build_list(:budget_line, 4, section: "Materials", budget: budget, account: budget.account, creator: budget.creator, amount_subunits: -2000)
        apply_sort_orders(materials_lines)

        budget.budget_lines = facilities_lines + materials_lines
        budget.save!
      end
    end
  end
end
