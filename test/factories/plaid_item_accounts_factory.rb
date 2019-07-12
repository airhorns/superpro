FactoryBot.define do
  factory :plaid_item_account do
    association :account
    association :plaid_item
    account_id { "foobar" }
    name { "Example Savings Account" }
    type { "depository" }
    subtype { "savings" }
  end
end
