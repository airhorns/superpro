class Types::Budget::BudgetLineFixedValueType < Types::BaseObject
  field :type, String, null: false
  field :occurs_at, GraphQL::Types::ISO8601DateTime, null: false
  field :recurrence_rules, [Types::RecurrenceRuleString], null: true
  field :amount_scenarios, Types::JSONScalar, null: false

  def type
    "fixed"
  end

  def occurs_at
    load_descriptor.then { |descriptor| descriptor.occurs_at }
  end

  def recurrence_rules
    load_descriptor.then { |descriptor| descriptor.recurrence_rules }
  end

  def amount_scenarios
    load_descriptor.then do |descriptor|
      AssociationLoader.for(FixedBudgetLineDescriptor, :budget_line_scenarios).load(descriptor).then do |scenarios|
        scenarios.each_with_object({}) do |scenario, agg|
          agg[scenario.scenario] = scenario.amount.fractional
        end
      end
    end
  end

  private

  def load_descriptor
    AssociationLoader.for(BudgetLine, :fixed_budget_line_descriptor).load(object)
  end
end
