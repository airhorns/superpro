# frozen_string_literal: true

class Types::Identity::AccountAttributes < Types::BaseInputObject
  description "Attributes for creating or updating an account"
  argument :name, String, "Name to set on the account", required: true
end
