class UpdateBudget
  def initialize(user)
    @user = user
  end

  def update(budget, attributes)
    success = Budget.transaction do
      budget.assign_attributes(attributes.except(:budget_lines))
      budget.budget_lines = new_budget_lines(budget, attributes[:budget_lines])
      budget.save
    end

    if success
      return budget, nil
    else
      return nil, budget.errors
    end
  end

  def new_budget_lines(budget, budget_line_attributes)
    existing_by_id = budget.budget_lines.index_by(&:id)
    budget_line_attributes.map do |attributes|
      existing = existing_by_id[attributes[:id]]
      line = if existing
               existing.update(attributes.except(:amount_scenarios))
             else
               budget.budget_lines.build(account: budget.account, creator: @user, **attributes.except(:id, :amount_scenarios))
             end

      line.budget_line_scenarios = attributes[:amount_scenarios].map do |key, amount|
        scenario = BudgetLineScenario.new(budget_line: line, account: budget.account, scenario: key, amount_subunits: amount, currency: "USD")
        scenario.series = expand_scenario(budget, scenario)
        scenario
      end
      line
    end
  end

  def expand_scenario(budget, scenario)
    series = Series.new(
      account: budget.account,
      creator: @user,
      scenario: scenario.scenario,
      currency: scenario.currency,
      x_type: "datetime",
      y_type: "money",
    )
    series
  end
end
