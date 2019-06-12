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

      line.budget_line_scenarios = attributes[:amount_scenarios].permit!.to_h.map do |key, amount|
        scenario = BudgetLineScenario.new(budget_line: line, account: budget.account, scenario: key, amount_subunits: amount, currency: "USD")
        scenario.series = expand_scenario(line, scenario)
        scenario
      end
      line
    end
  end

  def expand_scenario(budget_line, scenario)
    series = Series.new(
      account: budget_line.account,
      creator: @user,
      scenario: scenario.scenario,
      currency: scenario.currency,
      x_type: "datetime",
      y_type: "money",
    )

    # If the budget line is recurring, expand all the recurrence rules and create cells for each.
    # If it isn't recurring, add one cell for the time when the line occurs
    dates = if budget_line.recurrence_rules && budget_line.recurrence_rules.length > 0
              budget_line.recurrence_rules.flat_map do |rule_string|
                rule = RRule::Rule.new(rule_string.gsub(/\ARRULE:/, ""), dtstart: budget_line.occurs_at)
                rule.between(budget_line.occurs_at, Time.now.utc + 2.years)
              end.uniq
            else
              [budget_line.occurs_at]
            end

    dates.each do |date|
      series.cells.build(account: budget_line.account, x_datetime: date, y_money_subunits: scenario.amount_subunits)
    end

    series
  end
end
