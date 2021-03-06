# frozen_string_literal: true

FactoryBot.define do
  factory :shopify_connection, class: Connection do
    display_name { "Test Shopify Connection" }
    strategy { "singer" }
    association :account

    after(:build) do |connection|
      connection.integration ||= build(:shopify_shop, account: connection.account)
    end

    factory :shopify_hrsn_connection do
      after(:build) do |connection|
        connection.integration ||= build(:hrsn_shopify_shop, account: connection.account)
      end
    end
  end

  factory :plaid_connection, class: Connection do
    display_name { "Test Plaid Connection" }
    strategy { "plaid" }
    association :account

    integration_type { "PlaidItem" }
    integration_id { create(:plaid_item).id }
  end

  factory :google_analytics_connection, class: Connection do
    display_name { "Test GA Connection" }
    strategy { "singer" }
    association :account

    after(:build) do |connection|
      connection.integration ||= build(:google_analytics_credential, account: connection.account)
    end
  end

  factory :facebook_ads_connection, class: Connection do
    display_name { "Test Facebook Ads Connection" }
    strategy { "singer" }
    association :account

    after(:build) do |connection|
      connection.integration ||= build(:configured_facebook_ad_account, account: connection.account)
    end
  end
end
