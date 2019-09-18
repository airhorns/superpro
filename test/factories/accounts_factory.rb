# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    name { "Test Account" }

    association :creator, factory: :user
    business_epoch { Time.utc(2019, 0o1, 0o1, 0o1, 0o1, 0o0) }

    after(:create) do |account, _evaluator|
      create(:account_user_permission, account: account, user: account.creator)

      ["feature.shopify_script_tags"].each do |feature|
        Flipper[feature].enable(account)
      end
    end
  end
end
