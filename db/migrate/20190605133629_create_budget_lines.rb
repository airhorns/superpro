class CreateBudgetLines < ActiveRecord::Migration[6.0]
  def change
    create_table :budget_lines do |t|
      t.bigint :account_id, null: false
      t.bigint :creator_id, null: false
      t.bigint :budget_id, null: false
      t.string :description, null: false
      t.string :section, null: false
      t.datetime :occurs_at, null: false
      t.string :recurrence_rules, null: true, array: true
      t.integer :sort_order, null: false, default: 1

      t.timestamps
    end

    add_foreign_key :budget_lines, :accounts
    add_foreign_key :budget_lines, :budgets
    add_foreign_key :budget_lines, :users, column: :creator_id
  end
end
