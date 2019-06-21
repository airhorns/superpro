FactoryBot.define do
  factory :fixed_budget_line_descriptor do
    association :account
    association :budget_line
    recurrence_rules { ["FREQ=DAILY;COUNT=3"] }
    occurs_at { Time.now.utc }
  end
end
