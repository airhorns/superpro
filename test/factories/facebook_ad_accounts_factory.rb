# frozen_string_literal: true

FactoryBot.define do
  factory :facebook_ad_account do
    association :account
    association :creator, factory: :user
    access_token { ENV["FB_OAUTH_ACCESS_TOKEN"] }
    expires_at { Time.now.utc + 60.minutes }
    grantor_id { "10213720435438964" }
    grantor_name { "Joe Blow" }
    configured { false }

    factory :configured_facebook_ad_account do
      configured { false }
      fb_account_id { "act_57930665" }
      fb_account_name { "Test Account" }
    end
  end
end
