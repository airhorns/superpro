# frozen_string_literal: true

class Types::Connections::GoogleAnalyticsViewType < Types::BaseObject
  field :id, String, null: false
  field :name, String, null: false
  field :property_name, String, null: false
  field :property_id, String, null: false
  field :account_name, String, null: false
  field :account_id, String, null: false
  field :already_setup, Boolean, null: false
end
