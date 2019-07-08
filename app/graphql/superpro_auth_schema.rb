class SuperproAuthSchema < GraphQL::Schema
  mutation(Types::AuthMutationType)
  query(Types::AuthQueryType)
  use GraphQL::Batch
end
