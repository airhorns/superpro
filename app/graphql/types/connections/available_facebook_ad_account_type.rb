# frozen_string_literal: true

class Types::Connections::AvailableFacebookAdAccountType < Types::BaseObject
  field :id, String, null: false
  field :name, String, null: false
  field :account_status, String, null: false
  field :currency, String, null: false
  field :age, String, null: false
  field :already_setup, Boolean, null: false
end
