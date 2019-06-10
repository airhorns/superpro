FactoryBot.define do
  factory :budget_line_scenario do
    association :account
    association :budget_line
    scenario { "default" }
    currency { "USD" }
    amount_subunits { 100 }

    after(:build) do |scenario|
      scenario.series = build(:forecast_series, account: scenario.account, creator: scenario.budget_line.creator, cell_options: { y_money_subunits: scenario.amount_subunits })
    end
  end
end
