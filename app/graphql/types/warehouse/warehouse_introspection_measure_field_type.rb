# frozen_string_literal: true

class Types::Warehouse::WarehouseIntrospectionMeasureFieldType < Types::BaseObject
  field :field_name, String, null: false
  field :field_label, String, null: false
  field :data_type, Types::Warehouse::WarehouseDataTypeEnum, null: false
  field :allows_operators, Boolean, null: false
  field :requires_operators, Boolean, null: false
  field :default_operator, String, null: true
end
