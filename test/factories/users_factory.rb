FactoryBot.define do
  factory :user do
    sequence(:full_name) { |n| "Joe Bloweth The #{n}" }
    sequence(:email) { |n| "person#{n}@example.com" }

    after(:build) { |user|
      user.skip_confirmation!
      user.password_confirmation = user.password = "secrets"
    }

    factory :cypress_user do
      email { "cypress@superpro.io" }
      full_name { "Cypress Test User" }
    end
  end
end
