class CreateFixedBudgetLineDescriptors < ActiveRecord::Migration[6.0]
  def change
    create_table :fixed_budget_line_descriptors do |t|
      t.bigint :account_id, null: false
      t.datetime :occurs_at, null: false
      t.string :recurrence_rules, array: true

      t.timestamps
    end

    add_foreign_key :budget_line_scenarios, :fixed_budget_line_descriptors

    change_table :budget_lines, bulk: true do |t|
      t.bigint :fixed_budget_line_descriptor_id, null: true
      t.string :value_type, null: false
    end
  end
end
