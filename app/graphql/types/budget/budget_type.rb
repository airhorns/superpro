class Types::Budget::BudgetType < Types::BaseObject
  field :id, GraphQL::Types::ID, null: false
  field :name, String, null: false
  field :creator, Types::Identity::UserType, null: false
  field :budget_lines, [Types::Budget::BudgetLineType], null: false
  field :sections, [String], null: false

  field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  field :discarded_at, GraphQL::Types::ISO8601DateTime, null: false

  def budget_lines
    AssociationLoader.for(Budget, :budget_lines).load(object)
  end

  def sections
    AssociationLoader.for(Budget, :budget_lines).load(object).then { |lines| lines.map(&:section).uniq }
  end
end
