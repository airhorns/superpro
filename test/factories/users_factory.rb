# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:full_name) { |n| "Joe Bloweth The #{n}" }
    sequence(:email) { |n| "person#{n}@example.com" }

    after(:build) do |user|
      user.skip_confirmation!
      user.password_confirmation = user.password = "secrets"
    end

    factory :cypress_user do
      email { "cypress@superpro.io" }
      full_name { "Cypress Test User" }
    end
  end
end
