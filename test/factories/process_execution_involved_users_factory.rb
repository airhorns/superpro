FactoryBot.define do
  factory :process_execution_involved_user do
    association :account
    association :process_execution
    association :user
  end
end
