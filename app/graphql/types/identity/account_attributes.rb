# frozen_string_literal: true

class Types::Identity::AccountAttributes < Types::BaseInputObject
  description "Attributes for creating or updating an account"
  argument :name, String, "Name to set on the account", required: true
  argument :business_epoch, GraphQL::Types::ISO8601DateTime, "Date at which the business started doing business", required: false
end
