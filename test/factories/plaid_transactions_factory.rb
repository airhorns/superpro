FactoryBot.define do
  factory :plaid_transaction do
    association :account
    association :plaid_item
    plaid_account_identifier { "foobar" }
    sequence(:plaid_transaction_identifier) { |n| "foobar-#{n}" }
    category { [] }
    category_id { nil }
    transaction_type { "digital" }
    name { "Test transaction" }
    amount { "34.99" }
    iso_currency_code { "USD" }
    unofficial_currency_code { nil }
    date { "2019-07-12" }
  end
end
