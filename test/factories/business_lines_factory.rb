# frozen_string_literal: true
FactoryBot.define do
  factory :business_line do
    association :account
    association :creator, factory: :user
    name { "Direct to Consumer" }
  end
end
