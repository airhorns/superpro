class Types::Connections::ConnectionType < Types::BaseObject
  field :id, GraphQL::Types::ID, null: false
  field :display_name, String, null: false
  field :integration, Types::Connections::ConnectionProviderEnum, null: false
  field :enabled, Boolean, null: false

  field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
end
