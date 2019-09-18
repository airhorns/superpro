# frozen_string_literal: true

class Types::Connections::GoogleAnalyticsCredentialType < Types::BaseObject
  field :id, String, null: false
  field :configured, String, null: false
  field :view_name, String, null: false
  field :view_id, String, null: false
  field :property_name, String, null: false
  field :property_id, String, null: false
  field :account_id, String, null: false
  field :account_name, String, null: false
  field :grantor_name, String, null: false
  field :grantor_email, String, null: false

  def account_id
    object.ga_account_id
  end

  def account_name
    object.ga_account_name
  end
end
