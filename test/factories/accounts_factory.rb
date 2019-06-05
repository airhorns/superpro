FactoryBot.define do
  factory :account do
    name { "Test Account" }

    association :creator, factory: :user

    after(:create) do |account, _evaluator|
      create(:account_user_permission, account: account, user: account.creator)
      create(:base_operational_budget, account: account, creator: account.creator)
    end
  end
end
