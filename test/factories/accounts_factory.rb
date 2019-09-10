FactoryBot.define do
  factory :account do
    name { "Test Account" }

    association :creator, factory: :user
    business_epoch { Time.utc(2019, 01, 01, 01, 01, 00) }

    after(:create) do |account, _evaluator|
      create(:account_user_permission, account: account, user: account.creator)

      [].each do |feature|
        Flipper[feature].enable(account)
      end
    end
  end
end
