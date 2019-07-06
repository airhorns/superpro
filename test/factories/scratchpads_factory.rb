FactoryBot.define do
  factory :scratchpad do
    association :account
    association :creator, factory: :user
    access_mode { "private" }
    name { "New Scratchpad" }
    document { Todos::CreateScratchpad::DEFAULT_DOCUMENT }
    open_todo_count { 0 }
    closed_todo_count { 0 }
    total_todo_count { 0 }

    closest_future_deadline { nil }
    discarded_at { nil }
  end
end
