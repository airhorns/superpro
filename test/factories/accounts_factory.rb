FactoryBot.define do
  factory :account do
    name { "Test Account" }

    association :creator, factory: :user

    after(:create) do |account, _evaluator|
      create(:budget, account: account, creator: account.creator)
      create(:account_user_permission, account: account, user: account.creator)

      ["features.budgets", "features.todos", "features.connections"].each do |feature|
        Flipper[feature].enable(account)
      end
    end
  end
end
