FactoryBot.define do
  factory :process_execution do
    association :account
    association :creator, factory: :user
    name { "Example Process Execution" }
    document { CreateProcessTemplate::EMPTY_DOCUMENT.to_json }
    started_at { nil }
    discarded_at { nil }
  end
end
