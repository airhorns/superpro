# frozen_string_literal: true
FactoryBot.define do
  factory :customer_segment do
    account_id { "" }
    name { "MyString" }
    description { "MyText" }
    strategy { "MyString" }
    creator_id { "" }
  end
end
