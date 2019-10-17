# frozen_string_literal: true

module DataModel
  class WarehouseIntrospection
    def initialize(account, warehouse)
      @account = account
      @warehouse = warehouse
    end

    def fact_tables
      @warehouse.fact_tables.values.map do |fact_table|
        {
          name: fact_table.name,
          measure_fields: fact_table.measure_fields.values.map do |measure_field|
            {
              field_name: measure_field.field_name,
              field_label: measure_field.field_label,
              data_type: measure_field.data_type,
              allows_operators: measure_field.allows_operators?,
              requires_operators: measure_field.requires_operators?,
              default_operator: measure_field.default_operator,
            }
          end,
          dimension_fields: fact_table.dimension_fields.values.map do |dimension_field|
            {
              field_name: dimension_field.field_name,
              field_label: dimension_field.field_label,
              data_type: dimension_field.data_type,
              allows_operators: dimension_field.allows_operators?,
            }
          end,
          global_filter_fields: fact_table.global_filter_fields.map do |id, field|
            {
              filter_id: id,
              field: field,
            }
          end,
        }
      end
    end

    def operators
      @warehouse.operators.values.map do |operator|
        {
          key: operator.key,
        }
      end
    end
  end
end
