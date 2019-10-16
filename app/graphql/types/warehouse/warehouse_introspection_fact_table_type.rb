# frozen_string_literal: true

class Types::Warehouse::WarehouseIntrospectionFactTableType < Types::BaseObject
  field :name, String, null: false
  field :measure_fields, [Types::Warehouse::WarehouseIntrospectionMeasureFieldType], null: false
  field :dimension_fields, [Types::Warehouse::WarehouseIntrospectionDimensionFieldType], null: false
  field :global_filter_fields, [Types::Warehouse::WarehouseIntrospectionGlobalFilterFieldType], null: false
end
