# frozen_string_literal: true
module DataModel
  class QueryCompiler
    attr_reader :account, :warehouse, :query_specification, :aliases_by_id, :ids_by_alias

    def initialize(account, warehouse, query_specification)
      @account = account
      @warehouse = warehouse
      @query_specification = query_specification

      @aliases_by_id = {}
      @ids_by_alias = {}
      @alias_replace_counter = 0
    end

    def sql
      measures_by_model = @query_specification.fetch(:measures, []).group_by { |measure_spec| measure_spec[:model] }
      dimensions_by_model = @query_specification.fetch(:dimensions, []).group_by { |dimension_spec| dimension_spec[:model] }

      if measures_by_model.size > 1 || dimensions_by_model.size > 1
        throw RuntimeError.new("No support for cross model queries yet")
      end

      model_name = measures_by_model.keys.first || dimensions_by_model.keys.first
      model = @warehouse.fact_tables.fetch(model_name)
      measure_specs = measures_by_model[model_name] || []
      dimension_specs = dimensions_by_model[model_name] || []
      ordering_specs = @query_specification.fetch(:orderings, [])

      query = select_for_model(model, measure_specs, dimension_specs, ordering_specs)
      query.to_sql
    end

    private

    def select_for_model(model, measure_specs, dimension_specs, ordering_specs)
      table = Arel::Table.new(model.table)

      projections = []
      groups = []

      measure_specs.each do |measure_spec|
        alias_name = alias_for(measure_spec)
        projections << projection_node_for_measure_spec(table, model, measure_spec).as(alias_name)
      end

      dimension_specs.each do |dimension_spec|
        alias_name = alias_for(dimension_spec)
        projections << projection_node_for_dimension_spec(table, model, dimension_spec).as(alias_name)
        groups << Arel.sql(alias_name)
      end

      orders = ordering_specs.map { |ordering_spec| ordering_node_for_ordering_spec(ordering_spec) } || [default_ordering]

      if orders.empty?
        orders << default_ordering
      end

      manager = Arel::SelectManager.new
      manager.project(*projections)
      manager.group(*groups) if !groups.empty?
      manager.order(*orders) if !orders.empty?
      manager.from(table)
      manager.where(table[:account_id].eq(@account.id))
      manager.take(5000)

      manager
    end

    def projection_node_for_measure_spec(table, model, measure_spec)
      field = model.measure_fields.fetch(measure_spec[:field].to_sym)
      expression = field.custom_sql_node || table[field.field_name]

      if measure_spec[:operator]
        if !field.allows_operators?
          raise InvalidQueryError, "Field #{field.field_name} doesn't allow operators and was given #{measure_spec[:operator]} for measure id=#{measure_spec[:id]}"
        end

        expression = case measure_spec[:operator].to_sym
                     when :sum then expression.sum
                     when :count then expression.count
                     when :count_distinct then expression.count(true)
                     when :max then expression.maximum
                     when :min then expression.minimum
                     when :average then expression.average
                     else raise InvalidQueryError, "Unknown measure operator #{measure_spec[:operator]} for measure #{measure_spec[:model]}.#{measure_spec[:field]}"
                     end
      end

      expression
    end

    def projection_node_for_dimension_spec(table, model, dimension_spec)
      field = model.dimension_fields.fetch(dimension_spec[:field].to_sym)
      expression = field.custom_sql_node || table[field.field_name]

      if dimension_spec[:operator]
        expression = case dimension_spec[:operator].to_sym
                     when :date_trunc_day then Arel::Nodes::NamedFunction.new("date_trunc", [Arel.sql("'day'"), expression])
                     when :date_trunc_week then Arel::Nodes::NamedFunction.new("date_trunc", [Arel.sql("'week'"), expression])
                     when :date_trunc_month then Arel::Nodes::NamedFunction.new("date_trunc", [Arel.sql("'month'"), expression])
                     when :date_trunc_year then Arel::Nodes::NamedFunction.new("date_trunc", [Arel.sql("'year'"), expression])
                     else raise InvalidQueryError, "Unknown dimension operator #{dimension_spec[:operator]} for measure #{dimension_spec[:model]}.#{dimension_spec[:field]}"
                     end
      end

      expression
    end

    def ordering_node_for_ordering_spec(ordering_spec)
      alias_name = aliases_by_id.fetch(ordering_spec[:id])
      node = Arel.sql(alias_name)
      if ordering_spec[:direction] == "asc"
        node.asc
      else
        node.desc
      end
    end

    def default_ordering
      first_time_dimension = @query_specification[:dimensions]&.select { |spec| model_field_for(spec).data_type.datelike? }&.first

      if first_time_dimension
        ordering_node_for_ordering_spec(id: first_time_dimension[:id], direction: "asc")
      else
        first_measure = @query_specification[:measures].first
        if first_measure
          ordering_node_for_ordering_spec(id: first_measure[:id], direction: "desc")
        else
          first_dimension = @query_specification[:dimensions].first
          ordering_node_for_ordering_spec(id: first_dimension[:id], direction: "desc")
        end
      end
    end

    def model_field_for(spec)
      model = @warehouse.fact_tables.fetch(spec[:model])
      model.all_fields.fetch(spec[:field].to_sym)
    end

    def alias_for(spec)
      @aliases_by_id[spec[:id]] ||= begin
        segments = [spec[:model], spec[:field], spec[:operator]].compact.map { |segment| segment.gsub(/[^A-Za-z]/, "_").downcase }
        alias_name = segments.join("__")

        # Postgres truncates the AS silently, so we have to give it something shorter than 64 chars long
        if alias_name.size > 63
          replace_counter = (@alias_replace_counter += 1)
          prefix = "a_#{replace_counter}_"
          alias_name = prefix + alias_name[(alias_name.size - (63 - prefix.size))..-1]
        end

        raise "Incompatible postgres alias name #{alias_name}" if alias_name.size > 63

        @ids_by_alias[alias_name] ||= spec[:id]

        alias_name
      end
    end
  end
end
