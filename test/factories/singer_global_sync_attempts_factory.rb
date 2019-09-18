FactoryBot.define do
  factory :singer_global_sync_attempt do
    key { "MyString" }
    failure_reason { "MyString" }
    finished_at { "2019-09-17 19:19:14" }
    last_progress_at { "2019-09-17 19:19:14" }
    started_at { "2019-09-17 19:19:14" }
    success { false }
  end
end
