class Mutations::Connections::SetConnectionEnabled < Mutations::BaseMutation
  argument :connection_id, GraphQL::Types::ID, required: true
  argument :enabled, Boolean, required: true

  field :connection, Types::Connections::ConnectionobjType, null: true, connection: false
  field :errors, [String], null: true

  def resolve(connection_id:, enabled:)
    connection = context[:current_account].connections.find(connection_id)
    errors = nil

    enabler = Connections::ConnectionEnabler.new(context[:current_account], context[:current_user])
    if enabled
      enabler.enable(connection)
    else
      enabler.disable(connection)
    end

    {
      connection: connection,
      errors: errors,
    }
  end
end
