class Types::Todos::ProcessTemplateType < Types::BaseObject
  field :id, GraphQL::Types::ID, null: false
  field :name, String, null: false
  field :creator, Types::Identity::UserType, null: false
  field :document, Types::JSONScalar, null: false

  field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  field :discarded_at, GraphQL::Types::ISO8601DateTime, null: false
end
