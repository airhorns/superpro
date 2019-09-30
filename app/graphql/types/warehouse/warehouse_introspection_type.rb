# frozen_string_literal: true

class Types::Warehouse::WarehouseIntrospectionType < Types::BaseObject
  field :fact_tables, [Types::Warehouse::WarehouseIntrospectionFactTableType], null: false
  field :operators, [Types::Warehouse::WarehouseIntrospectionOperatorType], null: false
end
