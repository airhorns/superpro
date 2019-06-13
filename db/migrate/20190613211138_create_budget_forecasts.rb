class CreateBudgetForecasts < ActiveRecord::Migration[6.0]
  def change
    create_view :budget_forecasts
  end
end
