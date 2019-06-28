FactoryBot.define do
  factory :process_execution do
    account_id { "" }
    creator_id { "" }
    owner_id { "" }
    name { "MyString" }
    document { "" }
    started_at { "2019-06-28 17:34:39" }
    discarded_at { "2019-06-28 17:34:39" }
  end
end
