FactoryBot.define do
  factory :budget_line do
    association :account
    association :creator, factory: :user
    association :budget

    sequence(:description) { |n| "Line #{n}" }
    section { "Facilities" }
    recurrence_rules { ["FREQ=DAILY;COUNT=3"] }
    occurs_at { Time.now.utc }
    sequence(:sort_order) { |n| n }

    transient do
      amount_subunits { 100 }
    end

    after(:build) do |line, evaluator|
      line.series = build(:forecast_series, account: line.account, creator: line.creator, cell_options: { y_money_subunits: evaluator.amount_subunits })
      line.budget_line_scenarios << build(:budget_line_scenario, account: line.account, budget_line: line, amount_subunits: evaluator.amount_subunits)
    end
  end
end
