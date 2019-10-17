# frozen_string_literal: true

class Types::Identity::BusinessLineType < Types::BaseObject
  field :id, GraphQL::Types::ID, null: false
  field :name, String, null: false
end
