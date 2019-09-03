class Mutations::Connections::RestartConnectionSync < Mutations::BaseMutation
  argument :connection_id, GraphQL::Types::ID, required: true

  field :connection, Types::Connections::ConnectionobjType, null: true, connection: false
  field :errors, [String], null: true

  def resolve(connection_id:)
    connection = context[:current_account].connections.find(connection_id)
    errors = nil
    if connection.strategy_singer?
      Infrastructure::SingerConnectionSync.new(context[:current_account]).reset_state(connection)
      Infrastructure::SyncSingerConnectionJob.enqueue(connection_id: connection.id)
    else
      errors = ["Can't reset this connection right now."]
    end

    {
      connection: connection,
      errors: errors,
    }
  end
end
