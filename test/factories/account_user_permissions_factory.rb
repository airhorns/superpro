# frozen_string_literal: true

FactoryBot.define do
  factory :account_user_permission do
    association :account
    association :user
  end
end
