class Budgets::UpdateBudget
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
               existing.update(attributes.except(:value))
               existing
             else
               budget.budget_lines.build(account_id: budget.account_id, creator_id: @user.id, **attributes.except(:id, :value))
             end

      process_budget_line_value(line, attributes[:value])
      line
    end
  end

  def process_budget_line_value(budget_line, value_attributes)
    amounts = []

    if value_attributes[:type] == "fixed"
      descriptor = nil
      fixed_attrs = value_attributes.slice(:occurs_at, :recurrence_rules)
      if budget_line.fixed_budget_line_descriptor
        descriptor = budget_line.fixed_budget_line_descriptor
        descriptor.update(fixed_attrs)
      else
        descriptor = FixedBudgetLineDescriptor.new(account_id: budget_line.account_id, **fixed_attrs)
        budget_line.fixed_budget_line_descriptor = descriptor
        budget_line.value_type = "fixed"
      end

      existing_scenarios = descriptor.budget_line_scenarios.index_by(&:scenario)
      descriptor.budget_line_scenarios = value_attributes[:amount_scenarios].permit!.to_h.map do |key, amount|
        existing_scenario = existing_scenarios[key]
        if existing_scenario
          existing_scenario.update(amount_subunits: amount)
          existing_scenario
        else
          scenario = BudgetLineScenario.new(fixed_budget_line_descriptor: descriptor, account_id: budget_line.account_id, scenario: key, amount_subunits: amount, currency: "USD")
          scenario
        end
      end

      scenarios_by_key = descriptor.budget_line_scenarios.index_by(&:scenario)
      if scenarios_by_key["default"]
        # If the budget line is recurring, expand all the recurrence rules and create cells for each.
        # If it isn't recurring, add one cell for the time when the line occurs
        dates = if descriptor.recurrence_rules && descriptor.recurrence_rules.length > 0
                  descriptor.recurrence_rules.flat_map do |rule_string|
                    rule = RRule::Rule.new(rule_string, dtstart: descriptor.occurs_at)
                    rule.between(descriptor.occurs_at, Time.now.utc + 2.years)
                  end.uniq
                else
                  [descriptor.occurs_at]
                end

        amounts = dates.map do |date|
          value_attributes[:amount_scenarios].permit!.to_h.merge({ date_time: date })
        end
      end
    elsif value_attributes[:type] == "series"
      budget_line.value_type = "series"
      if budget_line.fixed_budget_line_descriptor
        budget_line.fixed_budget_line_descriptor.destroy
        budget_line.fixed_budget_line_descriptor = nil
      end

      amounts = value_attributes[:cells].map { |cell| cell[:amount_scenarios].permit!.to_h.merge({ date_time: cell[:date_time] }) }
    end

    process_budget_line_series(budget_line, amounts)
  end

  def process_budget_line_series(budget_line, amounts)
    series = budget_line.series || Series.new(
      account_id: budget_line.account_id,
      creator_id: @user.id,
      currency: "USD",
      x_type: "datetime",
      y_type: "money",
    )
    budget_line.series = series

    if !series.new_record?
      series.cells.delete_all
    else
      series.save!
    end

    if amounts.size > 0
      cells = amounts.map do |amount|
        if amount["default"]
          SCENARIO_KEYS.map do |scenario_key|
            {
              series_id: series.id,
              account_id: budget_line.account_id,
              scenario: scenario_key,
              x_datetime: amount[:date_time],
              y_money_subunits: amount[scenario_key],
              created_at: Time.now.utc,
              updated_at: Time.now.utc,
            }
          end
        end
      end
      cells.flatten!
      cells.compact!

      if cells.size > 0
        Cell.insert_all(cells)
        series.reload
      end
    end

    budget_line.series = series
  end
end
