# frozen_string_literal: true

FactoryBot.define do
  factory :google_analytics_credential do
    association :account
    association :creator, factory: :user
    token { ENV["GA_OAUTH_ACCESS_TOKEN"] }
    refresh_token { ENV["GA_OAUTH_REFRESH_TOKEN"] }
    expires_at { Time.now.utc + 60.minutes }
    grantor_name { "Joe Blow" }
    grantor_email { "joe@supo.dev" }
    view_id { 127652462 }
    configured { true }
  end
end
