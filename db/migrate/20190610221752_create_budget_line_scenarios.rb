class CreateBudgetLineScenarios < ActiveRecord::Migration[6.0]
  def change
    create_table :budget_line_scenarios do |t|
      t.bigint :account_id, null: false
      t.bigint :budget_line_id, null: false
      t.string :scenario, null: false
      t.string :currency, null: false
      t.bigint :amount_subunits, null: false
      t.bigint :series_id, null: false

      t.timestamps
    end

    add_foreign_key :budget_line_scenarios, :accounts
    add_foreign_key :budget_line_scenarios, :budget_lines
    add_index :budget_line_scenarios, [:account_id, :budget_line_id]
  end
end
