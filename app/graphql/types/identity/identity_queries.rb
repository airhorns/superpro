module Types::Identity::IdentityQueries
  extend ActiveSupport::Concern

  included do
    field :current_user, Types::Identity::UserType, null: false, description: "Get the details of the currently logged in user"
    field :current_account, Types::Identity::AccountType, null: false, description: "Get the details of the current account"
    field :users, Types::Identity::UserType.connection_type, null: false, description: "Get all the active users in the current account"
    field :plaid_items, Types::Identity::PlaidItemType.connection_type, null: false, description: "Get all the Plaid connections for the current account"
  end

  def current_account
    context[:current_account]
  end

  def current_user
    context[:current_user]
  end

  def users
    context[:current_account].permissioned_users
  end

  def plaid_items
    context[:current_account].plaid_items
  end
end
