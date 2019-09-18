# frozen_string_literal: true

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

    factory :sole_destroyer_shopify_shop do
      name { "Sole Destroyer" }
      api_key { "578a7c46941e7ed14ca5cca1d7244085" }
      password { "2707fc0219a6ce609c3481e53bb0947b" }
      shopify_domain { "sole-destroyer.myshopify.com" }
    end
  end
end
