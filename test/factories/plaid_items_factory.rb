# frozen_string_literal: true

FactoryBot.define do
  factory :plaid_item do
    association :account
    association :creator, factory: :user
    access_token { "TEST TOKEN" }
    item_id { "foobar" }
    initial_update_complete { false }
  end
end
