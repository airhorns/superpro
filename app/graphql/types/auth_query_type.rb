# frozen_string_literal: true

class Types::AuthQueryType < Types::BaseObject
  field :accounts, [Types::Identity::AccountType], null: false
  field :discarded_accounts, [Types::Identity::AccountType], null: false

  def accounts
    context[:current_user].permissioned_accounts.kept
  end

  def discarded_accounts
    context[:current_user].permissioned_accounts.discarded
  end
end
