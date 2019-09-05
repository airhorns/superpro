class Mutations::Connections::DiscardConnection < Mutations::BaseMutation
  argument :connection_id, GraphQL::Types::ID, required: true

  field :connection, Types::Connections::ConnectionobjType, null: true, connection: false
  field :errors, [String], null: true

  def resolve(connection_id:)
    connection = context[:current_account].connections.kept.find(connection_id)
    errors = nil

    Connections::DiscardConnection.new(context[:current_account], context[:current_user]).discard(connection)

    {
      connection: connection,
      errors: errors,
    }
  end
end
