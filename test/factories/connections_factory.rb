FactoryBot.define do
  factory :connection, class: Connection do
    display_name { "Test Shopify Connection" }
    association :account

    integration_type { "ShopifyShop" }
    integration_id { create(:shopify_shop).id }
  end

  factory :plaid_connection, class: Connection do
    display_name { "Test Plaid Connection" }
    association :account

    integration_type { "PlaidItem" }
    integration_id { create(:plaid_item).id }
  end
end
