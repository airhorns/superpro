FactoryBot.define do
  factory :budget_line do
    association :account
    association :creator, factory: :user
    association :budget

    section { "Facilities" }
    sequence(:description) { |n| "Line #{n}" }
    sequence(:sort_order) { |n| n }

    value_type { "fixed" }

    transient do
      amount_subunits { 100 }
    end

    after(:build) do |line, evaluator|
      line.series = build(:forecast_series, account: line.account, creator: line.creator, cell_options: { y_money_subunits: evaluator.amount_subunits })
      if line.value_type == "fixed"
        fixed_budget_line_descriptor = build(:fixed_budget_line_descriptor, account: line.account, budget_line: line)
        line.fixed_budget_line_descriptor = fixed_budget_line_descriptor
        fixed_budget_line_descriptor.budget_line_scenarios << build(:budget_line_scenario, account: line.account, fixed_budget_line_descriptor: fixed_budget_line_descriptor, amount_subunits: evaluator.amount_subunits)
      end
    end
  end
end
