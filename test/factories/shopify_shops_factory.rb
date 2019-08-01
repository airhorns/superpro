FactoryBot.define do
  factory :shopify_shop do
    sequence(:shopify_domain) { |n| "test-shop-#{n}.myshopify.com" }
    api_key { "foobar" }
    password { "secret" }
    name { "Test Shop" }
    shop_id { 1 }
    association :account
    association :creator, factory: :user

    factory :hrsn_shopify_shop do
      name { "hrsn Test Real Shop" }
      api_key { "f7cce5f3a9cba33093e5766d4fc0ee56" }
      password { "c313f81fe851b89b369f797cf99e3476" }
      shopify_domain { "hrsn.myshopify.com" }
    end
  end
end
