class Types::Budget::BudgetLineSeriesValueType < Types::BaseObject
  field :type, String, null: false
  field :cells, [Types::Budget::BudgetLineSeriesCellType], null: false

  def type
    "series"
  end

  def cells
    AssociationLoader.for(Series, :cells).load(object.series).then do |cells|
      cells.group_by(&:x_datetime).map do |datetime, cell_group|
        { date_time: datetime, amount_scenarios: cell_group.each_with_object({}) { |cell, obj| obj[cell.scenario] = cell.y_money_subunits } }
      end.sort_by { |cell| cell[:date_time] }
    end
  end
end
