class UpdateBudget
  SCENARIO_KEYS = ["default", "optimistic", "pessimistic"].freeze

  def initialize(user)
    @user = user
  end

  def update(budget, attributes)
    success = Budget.transaction do
      budget.assign_attributes(attributes.except(:budget_lines))
      budget.budget_lines = process_budget_lines(budget, attributes[:budget_lines])
      budget.save
    end

    if success
      return budget, nil
    else
      return nil, budget.errors
    end
  end

  def process_budget_lines(budget, budget_line_attributes)
    existing_by_id = budget.budget_lines.index_by { |line| line.id.to_s }

    budget_line_attributes.map do |attributes|
      existing = existing_by_id[attributes[:id].to_s]
      line = if existing
               existing.update(attributes.except(:amount_scenarios))
               existing
             else
               budget.budget_lines.build(account_id: budget.account_id, creator_id: @user.id, **attributes.except(:id, :amount_scenarios))
             end

      process_budget_line_scenarios(line, attributes[:amount_scenarios].permit!.to_h)
      process_budget_line_series(line)
      line
    end
  end

  def process_budget_line_scenarios(budget_line, amount_scenarios)
    existing_scenarios = budget_line.budget_line_scenarios.index_by(&:scenario)
    budget_line.budget_line_scenarios = amount_scenarios.map do |key, amount|
      existing_scenario = existing_scenarios[key]
      if existing_scenario
        existing_scenario.update(amount_subunits: amount)
        existing_scenario
      else
        scenario = BudgetLineScenario.new(budget_line: budget_line, account_id: budget_line.account_id, scenario: key, amount_subunits: amount, currency: "USD")
        scenario
      end
    end
  end

  def process_budget_line_series(budget_line)
    scenarios_by_key = budget_line.budget_line_scenarios.index_by(&:scenario)

    series = budget_line.series || Series.new(
      account_id: budget_line.account_id,
      creator_id: @user.id,
      currency: "USD",
      x_type: "datetime",
      y_type: "money",
    )

    if !series.new_record?
      series.cells.delete_all
    else
      series.save!
    end

    if scenarios_by_key["default"]
      # If the budget line is recurring, expand all the recurrence rules and create cells for each.
      # If it isn't recurring, add one cell for the time when the line occurs
      dates = if budget_line.recurrence_rules && budget_line.recurrence_rules.length > 0
                budget_line.recurrence_rules.flat_map do |rule_string|
                  rule = RRule::Rule.new(rule_string, dtstart: budget_line.occurs_at)
                  rule.between(budget_line.occurs_at, Time.now.utc + 2.years)
                end.uniq
              else
                [budget_line.occurs_at]
              end

      cells = dates.map do |date|
        SCENARIO_KEYS.map do |scenario_key|
          scenario = scenarios_by_key[scenario_key] || scenarios_by_key["default"]
          {
            series_id: series.id,
            account_id: budget_line.account_id,
            scenario: scenario_key,
            x_datetime: date,
            y_money_subunits: scenario.amount_subunits,
            created_at: Time.now.utc,
            updated_at: Time.now.utc,
          }
        end
      end.flatten

      Cell.insert_all(cells)
    end

    budget_line.series = series
  end
end
