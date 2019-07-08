class Types::Todos::ScratchpadType < Types::BaseObject
  field :id, GraphQL::Types::ID, null: false
  field :creator, Types::Identity::UserType, null: false
  field :document, Types::JSONScalar, null: false
  field :name, String, null: false

  field :open_todo_count, Integer, null: false
  field :closed_todo_count, Integer, null: false
  field :total_todo_count, Integer, null: false
  field :closest_future_deadline, GraphQL::Types::ISO8601DateTime, null: true
  field :access_mode, Types::Todos::ScratchpadAccessModeEnum, null: false

  field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  field :discarded_at, GraphQL::Types::ISO8601DateTime, null: false
end
