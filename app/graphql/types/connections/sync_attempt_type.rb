# frozen_string_literal: true

class Types::Connections::SyncAttemptType < Types::BaseObject
  field :id, GraphQL::Types::ID, null: false
  field :success, Boolean, null: true
  field :failure_reason, String, null: true

  field :started_at, GraphQL::Types::ISO8601DateTime, null: false
  field :finished_at, GraphQL::Types::ISO8601DateTime, null: true
  field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
end
