class Types::BaseObject < GraphQL::Schema::Object
  connection_type_class(Types::BaseRelayConnectionType)
end
