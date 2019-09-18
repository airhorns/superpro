# frozen_string_literal: true

class SuperproAuthSchema < GraphQL::Schema
  mutation(Types::AuthMutationType)
  query(Types::AuthQueryType)
  use GraphQL::Batch
end
