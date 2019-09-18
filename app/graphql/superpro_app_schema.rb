# frozen_string_literal: true

class SuperproAppSchema < GraphQL::Schema
  mutation(Types::AppMutationType)
  query(Types::AppQueryType)
  use GraphQL::Batch
end
