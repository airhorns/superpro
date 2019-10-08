# frozen_string_literal: true

class Types::Warehouse::WarehouseQueryResultType < Types::BaseObject
  field :records, [Types::JSONScalar], null: true
  field :output_introspection, Types::Warehouse::WarehouseOutputIntrospectionType, null: true
  field :errors, [String], null: true
end
