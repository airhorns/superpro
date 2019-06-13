class Types::Budget::BudgetType < Types::BaseObject
  field :id, GraphQL::Types::ID, null: false
  field :name, String, null: false
  field :creator, Types::Identity::UserType, null: false
  field :budget_lines, [Types::Budget::BudgetLineType], null: false
  field :sections, [String], null: false
  field :problem_spots, [Types::Budget::BudgetProblemSpotType], null: false

  field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  field :discarded_at, GraphQL::Types::ISO8601DateTime, null: false

  def budget_lines
    AssociationLoader.for(Budget, :budget_lines).load(object)
  end

  def sections
    AssociationLoader.for(Budget, :budget_lines).load(object).then { |lines| lines.map(&:section).uniq }
  end

  def problem_spots
    Budget.connection.execute("SELECT spot_number, scenario, start_date::timestamp, end_date::timestamp, min_cash_on_hand FROM budget_problem_spots WHERE budget_id = #{object.id}").to_a.map do |result|
      {
        spot_number: result["spot_number"],
        scenario: result["scenario"],
        start_date: result["start_date"],
        end_date: result["end_date"],
        min_cash_on_hand: Money.new(result["min_cash_on_hand"], "USD"),
      }
    end
  end
end
