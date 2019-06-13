class CreateBudgetProblemSpots < ActiveRecord::Migration[6.0]
  def change
    create_view :budget_problem_spots
  end
end
