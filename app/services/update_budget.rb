class UpdateBudget
  def initialize(user)
    @user = user
  end

  def update(budget, attributes)
    success = Budget.transaction do
      budget.assign_attributes(attributes.except(:budget_lines))
      budget.budget_lines = new_budget_lines(budget, attributes[:budget_lines])
      saved = budget.save
      if saved
        expand_series(budget)
      end
      saved
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
               existing.update_attributes(attributes.except(:scenarios))
             else
               budget.budget_lines.build(attributes.except(:id, :scenarios))
             end
    end
  end

  def expand_series(budget)
  end
end
