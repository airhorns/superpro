FactoryBot.define do
  factory :budget_line do
    association :account
    association :creator, factory: :user
    association :budget
    sequence(:description) { |n| "Line #{n}" }
    variable { false }
    section { "Facilities" }
    recurrence_rules { ["FREQ=DAILY;COUNT=3"] }
    amount_subunits { 2000 }
    currency { "USD" }
    sequence(:sort_order) { |n| n }
  end
end
