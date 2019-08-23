FactoryBot.define do
  factory :google_analytics_credential do
    association :account
    association :creator, factory: :user
    token { "deadbeef" }
    refresh_token { "deadbeef" }
    expires_at { "2019-08-21 16:39:57" }
    grantor_name { "Joe Blow" }
    grantor_email { "joe@supo.dev" }
    view_id { 1234 }
    configured { true }
  end
end
