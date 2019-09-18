# frozen_string_literal: true

FactoryBot.define do
  factory :singer_sync_state do
    association :account
    association :connection, factory: :shopify_connection
    state { {}.to_json }
  end
end
