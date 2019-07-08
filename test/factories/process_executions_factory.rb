FactoryBot.define do
  factory :process_execution do
    association :account
    association :creator, factory: :user
    name { "Example Process Execution" }
    document { Todos::CreateProcessTemplate::EMPTY_DOCUMENT.to_json }
    closest_future_deadline { nil }

    started_at { nil }
    discarded_at { nil }
  end
end
