# frozen_string_literal: true
module DataModel
  class QueryCompiler
    attr_reader :account, :warehouse, :query_specification, :aliases_by_id, :ids_by_alias

    def initialize(account, warehouse, query_specification)
      @account = account
      @warehouse = warehouse
      @query_specification = query_specification
      @has_aggregations_visitor = HasAggregationsNodeVisitor.new

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
      filter_specs = @query_specification.fetch(:filters, [])

      query = select_for_model(model, measure_specs, dimension_specs, ordering_specs, filter_specs)
      query.to_sql
    end

    private

    def select_for_model(model, measure_specs, dimension_specs, ordering_specs, filter_specs)
      table = Arel::Table.new(model.table)

      projections = []
      groups = []
      joins = []
      projections_by_id = {}

      measure_specs.each do |measure_spec|
        alias_name = column_alias_for(measure_spec)
        node = projection_node_for_measure_spec(model, measure_spec)
        projections << safe_alias_node(node, alias_name)
        projections_by_id[measure_spec[:id]] = { node: node, spec: measure_spec, type: :measure, alias_name: alias_name }
      end

      dimension_specs.each do |dimension_spec|
        alias_name = column_alias_for(dimension_spec)
        node = projection_node_for_dimension_spec(model, dimension_spec)
        projections << safe_alias_node(node, alias_name)
        groups << Arel.sql(alias_name)
        projections_by_id[dimension_spec[:id]] = { node: node, spec: dimension_spec, type: :dimension, alias_name: alias_name }

        join_node = join_node_for_dimension_spec(model, dimension_spec)
        if join_node
          joins << join_node
        end
      end

      orders = ordering_specs.map { |ordering_spec| ordering_node_for_ordering_spec(ordering_spec) } || [default_ordering]
      if orders.empty?
        orders << default_ordering
      end

      filters = filter_specs.map { |filter_spec| filter_node_for_filter_spec(model, projections_by_id, filter_spec) }
      filters << table[:account_id].eq(@account.id)
      havings, wheres = filters.partition { |filter| contains_aggregation_nodes?(filter) }

      manager = Arel::SelectManager.new
      manager.project(*projections)
      manager.group(*groups) if !groups.empty?
      manager.order(*orders) if !orders.empty?
      manager.from(table)
      joins.uniq.each { |join| manager.from(join) }
      wheres.each { |filter| manager.where(filter) }
      havings.each { |filter| manager.having(filter) }
      manager.take(@query_specification.fetch(:limit, 5000))

      manager
    end

    def projection_node_for_measure_spec(model, measure_spec)
      field = model.measure_fields.fetch(measure_spec[:field].to_sym)
      expression = field.custom_sql_node || model.table_node[field.field_name]

      if measure_spec[:operator]
        expression = apply_operator(expression, field, measure_spec[:operator].to_sym)
      elsif field.default_operator
        expression = apply_operator(expression, field, field.default_operator)
      end

      expression
    end

    def projection_node_for_dimension_spec(model, dimension_spec)
      field = model.dimension_fields.fetch(dimension_spec[:field].to_sym)
      source_table = field.requires_join? ? field.join.model.table_node : model.table_node
      expression = field.custom_sql_node || source_table[field.column_name]

      if dimension_spec[:operator]
        expression = apply_operator(expression, field, dimension_spec[:operator].to_sym)
      end

      expression
    end

    def join_node_for_dimension_spec(model, dimension_spec)
      field = model.dimension_fields.fetch(dimension_spec[:field].to_sym)
      if field.join
        relation_node = field.join.model.table_node
        fact_join_column = model.table_node[field.join.key_in_fact_table]
        dimension_primary_column = field.join.model.table_node[field.join.model.primary_key]
        constraint_node = Arel::Nodes::On.new(fact_join_column.eq(dimension_primary_column))

        model.table_node.create_join relation_node, constraint_node, Arel::Nodes::OuterJoin
      end
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

    def filter_node_for_filter_spec(model, projections_by_id, filter_spec)
      values = filter_spec[:values]
      node = if filter_spec.key?(:id)
               projections_by_id.fetch(filter_spec[:id])[:node]
             elsif filter_spec.key?(:field)
               field = filter_spec[:field][:field].to_sym
               if model.measure_fields.key?(field)
                 projection_node_for_measure_spec(model, filter_spec[:field])
               else
                 projection_node_for_dimension_spec(model, filter_spec[:field])
               end
             end

      case filter_spec[:operator].to_sym
      when :equals then node.eq_any(values)
      when :not_equals then node.not_eq_any(values)
      when :greater_than then node.gt_all(values)
      when :greater_than_or_equals then node.gteq_all(values)
      when :less_than then node.lt_all(values)
      when :less_than_or_equals then node.lteq_all(values)
      when :is_null then node.eq(nil)
      when :is_not_null then node.not_eq(nil)
      else raise InvalidQueryError, "Unknown filter operator #{filter_spec[:operator]} for filter on id=#{filter_spec[:id]}"
      end
    end

    def apply_operator(expression, field, operator)
      if !field.allows_operators?
        raise InvalidQueryError, "Field #{field.field_name} doesn't allow operators and was given #{operator}"
      end

      operator = self.warehouse.operators[operator]

      if !operator
        raise InvalidQueryError, "Unknown operator #{operator}"
      end

      if !operator.valid_on_type?(field.data_type)
        raise InvalidQueryError, "Operator #{operator.key} is invalid on this field #{field.field_name} because it's type is #{field.data_type}"
      end

      operator.apply(expression)
    end

    def contains_aggregation_nodes?(node)
      @has_aggregations_visitor.accept(node)
    end

    def model_field_for(spec)
      model = @warehouse.fact_tables.fetch(spec[:model])
      model.all_fields.fetch(spec[:field].to_sym)
    end

    def column_alias_for(spec)
      @aliases_by_id[spec[:id]] ||= begin
        segments = [spec[:model], spec[:field], spec[:operator]].compact.map { |segment| segment.gsub(/^[^A-Za-z]/, "_").gsub(/[^A-Za-z0-9]/, "_").downcase }
        alias_name = segments.join("__")

        # Postgres truncates aliases names after the AS silently, so we have to give it something shorter than 64 chars long
        # to be able to re-reference it later
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

    # it'd be great to just call Node.as when we needed to alias stuff, but that does one thing for basic nodes that isn't an internal mutation, but a different thing on ExpressionNodes, which is. That makes it unsafe to alias stuff and then leave the nodes around for other bits of code to use, so we use this helper that doesn't mutate any of the nodes instead.
    def safe_alias_node(node, name)
      Arel::Nodes::As.new node, Arel::Nodes::SqlLiteral.new(name)
    end
  end
end
