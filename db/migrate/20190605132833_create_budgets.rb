class CreateBudgets < ActiveRecord::Migration[6.0]
  def change
    create_table :budgets do |t|
      t.bigint :account_id, null: false
      t.bigint :creator_id, null: false
      t.string :name, null: false
      t.datetime :discarded_at

      t.timestamps
    end

    add_foreign_key :budgets, :accounts
    add_foreign_key :budgets, :users, column: :creator_id
  end
end
