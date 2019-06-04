module Types::Identity::IdentityQueries
  extend ActiveSupport::Concern

  included do
    field :current_user, Types::Identity::UserType, null: false, description: "Get the details of the currently logged in user"
    field :current_account, Types::Identity::AccountType, null: false, description: "Get the details of the current account"
  end

  def current_account
    context[:current_account]
  end

  def current_user
    context[:current_user]
  end
end
