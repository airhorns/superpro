# frozen_string_literal: true

module DataModel
  class QueryIntrospection
    def initialize(account, warehouse, query_specification)
      @account = account
      @warehouse = warehouse
      @query_specification = query_specification

      @fields_by_id = (@query_specification.fetch(:measures, []) + @query_specification.fetch(:dimensions, [])).index_by { |spec| spec[:id].to_s }
    end

    def as_json
      @as_json ||= {
        types: @fields_by_id.transform_values { |spec| type_for_field_spec(spec).to_enum },
      }
    end

    def type_for_field_id(id)
      type_for_field_spec(@fields_by_id.fetch(id.to_s))
    end

    def type_for_field_spec(spec)
      model_field_for_field_spec(spec).data_type
    end

    def model_field_for_field_spec(spec)
      model = @warehouse.fact_tables[spec[:model]] || @warehouse.dimension_tables[spec[:model]]
      if model.nil?
        raise "Unknown model field in spec #{spec}"
      end

      model.all_fields.fetch(spec[:field].to_sym)
    end
  end
end
