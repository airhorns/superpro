# frozen_string_literal: true

module DataModel
  class Pivot
    include SemanticLogger::Loggable

    def initialize(account, warehouse, query, pivot_specification)
      @account = account
      @warehouse = warehouse
      @query = query
      @pivot_specification = pivot_specification
      @generated_index = 0
      @generated_columns = Hash.new { |hash, key| hash[key] = {} }
    end

    def run(results)
      all_field_values_list = pivot_columns.map { |field| results.map { |result| result[field] }.uniq }
      pivot_column_values_list = all_field_values_list[0].product(*all_field_values_list[1..-1])

      results.group_by { |result| result.values_at(*group_columns) }.map do |key, record_group|
        pivoted = {}
        group_columns.each_with_index do |field, index|
          pivoted[field] = key[index]
        end

        measure_columns.each do |measure_column|
          pivot_column_values_list.each do |pivot_column_values|
            output_column_name = column_name(measure_column, pivot_column_values)

            # Find the raw record for this group that matches the pivot values
            record = record_group.detect do |candidate|
              pivot_columns.each_with_index.all? { |column, index| candidate[column] == pivot_column_values[index] }
            end

            pivoted[output_column_name] = record.present? ? record[measure_column] : nil
          end
        end

        pivoted
      end
    end

    def group_columns
      @group_columns ||= (@query.all_field_ids - measure_columns) - pivot_columns
    end

    def pivot_columns
      @pivot_columns ||= @pivot_specification[:pivot_field_ids]
    end

    def measure_columns
      @measure_columns ||= @pivot_specification[:measure_ids]
    end

    def generated_columns
      @generated_columns.values.map(&:values).flatten
    end

    private

    def column_name(measure_column, pivot_column_values)
      @generated_columns[measure_column][pivot_column_values] ||= begin
        generated_id = "pivot_#{measure_column}_#{@generated_index += 1}"
        {
          measure_column: measure_column,
          pivot_column_values: pivot_column_values,
          pivot_group_id: @pivot_specification[:id],
          id: generated_id,
        }
      end

      @generated_columns[measure_column][pivot_column_values][:id]
    end
  end
end
