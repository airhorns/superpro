class Types::Todos::TodoFeedItemType < Types::BaseObject
  field :id, GraphQL::Types::ID, null: false
  field :creator, Types::Identity::UserType, null: false
  field :todo_source, Types::Todos::TodoFeedItemSourceUnion, null: false

  field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

  def todo_source
    AssociationLoader.for(TodoFeedItem, :todo_source).load(object)
  end
end
