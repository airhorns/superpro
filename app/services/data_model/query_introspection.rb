# frozen_string_literal: true

module DataModel
  class QueryIntrospection
    def initialize(account, warehouse, query_specification)
      @account = account
      @warehouse = warehouse
      @query_specification = query_specification

      @specs_by_id = (@query_specification.fetch(:measures, []) + @query_specification.fetch(:dimensions, [])).index_by { |spec| spec[:id].to_s }
    end

    def as_json
      @as_json ||= {
        fields: @specs_by_id.values.map do |spec|
          field = model_field_for_field_spec(spec)
          operator = operator_for_field_spec(spec)
          {
            id: spec[:id],
            type: operator.present? ? operator.output_type(field) : field.data_type.to_enum,
            label: human_label(spec, field),
            sortable: false,
          }
        end,
      }
    end

    def type_for_field_id(id)
      type_for_field_spec(@specs_by_id.fetch(id.to_s))
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

    def operator_for_field_spec(spec)
      return nil if spec[:operator].nil?
      @warehouse.operators.fetch(spec[:operator].to_sym)
    end

    def human_label(spec, field)
      title = field.field_label
      case spec[:operator]
      when "date_trunc_year" then "#{title} Year"
      when "date_trunc_month" then "#{title} Month"
      when "date_trunc_week" then "#{title} Week"
      when "date_trunc_day" then "#{title} Date"
      when "date_part_hour" then "Hour of #{title}"
      when "date_part_day_of_month" then "Day of Month of #{title}"
      when "date_part_day_of_week" then "Day of Week of #{title}"
      when "date_part_week" then "Week of #{title}"
      when "date_part_month" then "Month of #{title}"
      when "date_part_year" then "Year of #{title}"
      when "average" then "Average #{title}"
      when "sum" then "Sum of #{title}"
      when "max" then "Maximum #{title}"
      when "min" then "Minimum #{title}"
      when "count" then "Count of #{title}"
      when "count_distinct" then "Count of Unique #{title}"
      when "p80" then "80th Percentile #{title}"
      when "p90" then "90th Percentile #{title}"
      when "p95" then "95th Percentile #{title}"
      else title
      end
    end
  end
end
