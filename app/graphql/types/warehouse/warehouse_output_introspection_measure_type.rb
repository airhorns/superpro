# frozen_string_literal: true

class Types::Warehouse::WarehouseOutputIntrospectionMeasureType < Types::BaseObject
  field :id, String, null: false
  field :pivot_group_id, String, null: true
  field :data_type, Types::Warehouse::WarehouseDataTypeEnum, null: false
  field :label, String, null: false
  field :sortable, Boolean, null: false
end
