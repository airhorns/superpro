FactoryBot.define do
  factory :process_template do
    association :account
    association :creator, factory: :user
    name { "Test Process" }
    document { "{}" }
  end
end
