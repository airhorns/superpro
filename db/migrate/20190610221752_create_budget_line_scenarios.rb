class CreateBudgetLineScenarios < ActiveRecord::Migration[6.0]
  def change
    create_table :budget_line_scenarios do |t|
      t.bigint :account_id, null: false
      t.bigint :fixed_budget_line_descriptor_id, null: false
      t.string :scenario, null: false
      t.string :currency, null: false
      t.bigint :amount_subunits, null: false

      t.timestamps
    end

    add_foreign_key :budget_line_scenarios, :accounts
    add_index :budget_line_scenarios, [:account_id, :fixed_budget_line_descriptor_id], name: "idx_scenarios_to_fixed_descriptors"
  end
end
