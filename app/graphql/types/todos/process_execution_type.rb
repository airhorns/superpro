class Types::Todos::ProcessExecutionType < Types::BaseObject
  field :id, GraphQL::Types::ID, null: false
  field :name, String, null: false
  field :creator, Types::Identity::UserType, null: false
  field :owner, Types::Identity::UserType, null: false
  field :document, Types::JSONScalar, null: false
  field :process_template, Types::Todos::ProcessTemplateType, null: true

  field :started_at, GraphQL::Types::ISO8601DateTime, null: false
  field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  field :discarded_at, GraphQL::Types::ISO8601DateTime, null: false
end
