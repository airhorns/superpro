# frozen_string_literal: true

# This class has a weird name because if it's named ConnectionType it collides with something inside GraphQL and throws super duper weird errors all over the place.
class Types::Connections::ConnectionobjType < Types::BaseObject
  field :id, GraphQL::Types::ID, null: false
  field :display_name, String, null: false
  field :integration, Types::Connections::ConnectionIntegrationUnion, null: false
  field :enabled, Boolean, null: false
  field :supports_sync, Boolean, null: false
  field :supports_test, Boolean, null: false
  field :sync_attempts, Types::Connections::SyncAttemptType.connection_type, null: false

  field :discarded_at, GraphQL::Types::ISO8601DateTime, null: true
  field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

  def supports_sync
    object.strategy_singer?
  end

  def supports_test
    false
  end

  def sync_attempts
    object.singer_sync_attempts.order("created_at DESC")
  end

  def integration
    AssociationLoader.for(Connection, :integration).load(object)
  end
end
