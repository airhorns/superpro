# frozen_string_literal: true

module DataModel
  class OutputIntrospection
    def initialize(query, pivot = nil)
      @query = query
      @pivot = pivot
      @warehouse = query.warehouse
    end

    def measures
      base_measure_introspections = @query.measures.map { |spec| base_field_introspection(spec) }

      if @pivot
        base_measure_introspections_by_id = base_measure_introspections.index_by { |intro| intro[:id] }

        @pivot.generated_columns.map do |generated_column|
          base_introspection = base_measure_introspections_by_id.fetch(generated_column[:measure_column])

          {
            id: generated_column[:id],
            data_type: base_introspection[:data_type],
            label: human_pivot_label(generated_column),
            sortable: false,
            pivot_group_id: generated_column[:pivot_group_id],
          }
        end
      else
        base_measure_introspections
      end
    end

    def dimensions
      dimensions = @query.dimensions

      if @pivot
        dimensions = dimensions.reject { |spec| @pivot.pivot_columns.include?(spec[:id]) }
      end

      dimensions.map do |spec|
        base_field_introspection(spec)
      end
    end

    def pivoted_measures
      if @pivot
        @query.measures.filter { |spec| @pivot.measure_columns.include?(spec[:id]) }.map { |spec| base_field_introspection(spec) }
      else
        []
      end
    end

    def base_field_introspection(spec)
      field = @query.model_field_for_field_spec(spec)
      operator = operator_for_field_spec(spec)
      {
        id: spec[:id],
        data_type: operator.present? ? operator.output_type(field) : field.data_type,
        label: human_label(spec, field),
        sortable: false,
      }
    end

    def operator_for_field_spec(spec)
      return nil if spec[:operator].nil?
      @warehouse.operators.fetch(spec[:operator].to_sym)
    end

    def human_pivot_label(generated_column)
      generated_column[:pivot_column_values].join(", ")
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
