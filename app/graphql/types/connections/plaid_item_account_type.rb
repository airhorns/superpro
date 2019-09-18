# frozen_string_literal: true

class Types::Connections::PlaidItemAccountType < Types::BaseObject
  field :id, GraphQL::Types::ID, null: false
  field :name, String, null: false
  field :type, String, null: false
  field :subtype, String, null: false
  field :created_at, GraphQL::Types::ISO8601DateTime, null: false
end
