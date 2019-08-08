FactoryBot.define do
  factory :account do
    name { "Test Account" }

    association :creator, factory: :user

    after(:create) do |account, _evaluator|
      create(:account_user_permission, account: account, user: account.creator)

      [].each do |feature|
        Flipper[feature].enable(account)
      end
    end
  end
end
