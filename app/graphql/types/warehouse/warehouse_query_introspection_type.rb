# frozen_string_literal: true

class Types::Warehouse::WarehouseQueryIntrospectionType < Types::BaseObject
  field :types, Types::JSONScalar, null: false
  field :fields, [Types::Warehouse::WarehouseQueryIntrospectionFieldType], null: false
end
