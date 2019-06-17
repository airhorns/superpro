# == Schema Information
#
# Table name: series
#
#  id         :bigint(8)        not null, primary key
#  currency   :string
#  x_type     :string           not null
#  y_type     :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint(8)        not null
#  creator_id :bigint(8)        not null
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (creator_id => users.id)
#

FactoryBot.define do
  factory :series do
    association :account
    association :creator, factory: :user
    x_type { "number" }
    y_type { "number" }

    transient {
      cell_factory { :number_cell }
      cell_options { Hash.new }
    }

    factory :forecast_series do
      x_type { "datetime" }
      y_type { "money" }
      currency { "USD" }
      cell_factory { :forecast_cell }
    end

    after(:build) do |series, evaluator|
      cells = []
      UpdateBudget::SCENARIO_KEYS.each do |key|
        cells += build_list(evaluator.cell_factory, 5, account: series.account, series: series, scenario: key, **evaluator.cell_options)
      end
      series.cells = cells
    end
  end
end
