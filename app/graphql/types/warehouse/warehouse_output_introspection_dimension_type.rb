# frozen_string_literal: true

class Types::Warehouse::WarehouseOutputIntrospectionDimensionType < Types::BaseObject
  field :id, String, null: false
  field :data_type, Types::Warehouse::WarehouseDataTypeEnum, null: false
  field :operator, String, null: true
  field :label, String, null: false
  field :sortable, Boolean, null: false
end
