# frozen_string_literal: true

class Types::Identity::UserType < Types::BaseObject
  field :id, GraphQL::Types::ID, null: false
  field :full_name, String, null: true
  field :email, String, null: false
  field :primary_text_identifier, String, null: false
  field :secondary_text_identifier, String, null: true

  field :pending_invitation, Boolean, null: false

  field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

  field :accounts, [Types::Identity::AccountType], null: false
  field :auth_area_url, String, null: false

  def primary_text_identifier
    object.full_name || object.email
  end

  def secondary_text_identifier
    if object.full_name.present?
      object.email
    end
  end

  def accounts
    if object == context[:current_user]
      object.permissioned_accounts.kept
    else
      []
    end
  end

  def auth_area_url
    Rails.application.routes.url_helpers.auth_root_url
  end

  def pending_invitation
    !object.accepted_or_not_invited?
  end
end
