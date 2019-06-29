FactoryBot.define do
  factory :process_execution do
    association :account
    association :creator, factory: :user
    association :owner, factory: :user
    name { "Example Process Execution" }
    document { "{}" }
    started_at { nil }
    discarded_at { nil }
  end
end
