FactoryBot.define do
  factory :shopify_shop do
    sequence(:shopify_domain) { |n| "test-shop-#{n}.myshopify.com" }
    api_key { "foobar" }
    password { "secret" }
    name { "Test Shop" }
    shop_id { 1 }
    association :account
    association :creator, factory: :user
  end
end
