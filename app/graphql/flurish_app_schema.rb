class FlurishAppSchema < GraphQL::Schema
  # mutation(Types::AppMutationType)
  query(Types::AppQueryType)
  use GraphQL::Batch
end
