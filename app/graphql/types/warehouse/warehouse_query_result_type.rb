# frozen_string_literal: true

class Types::Warehouse::WarehouseQueryResultType < Types::BaseObject
  field :records, [Types::JSONScalar], null: true
  field :query_introspection, Types::Warehouse::WarehouseQueryIntrospectionType, null: true
  field :errors, [String], null: true
end
