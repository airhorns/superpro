FactoryBot.define do
  factory :user do
    sequence(:full_name) { |n| "Joe Bloweth The #{n}" }
    sequence(:email) { |n| "person#{n}@example.com" }

    after(:build) { |user| user.password_confirmation = user.password = "secrets" }

    factory :cypress_user do
      email { "cypress@gapp.fun" }
      full_name { "Cypress Test User" }

      after(:build) { |user| user.skip_confirmation! }
    end
  end
end
