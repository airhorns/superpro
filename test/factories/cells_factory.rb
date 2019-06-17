FactoryBot.define do
  factory :number_cell, class: Cell do
    association :account
    association :series
    scenario { "default" }
    sequence(:x_number) { |n| n }
    sequence(:y_number) { |n| n }
  end

  factory :forecast_cell, class: Cell do
    association :account
    association :series, factory: :forecast_series
    scenario { "default" }
    sequence(:x_datetime) { |n| Time.utc(2020, "jan", (n % 20) + 1, 10, 1, 1) }
    sequence(:y_money_subunits) { |n| n * 100 }
  end
end
