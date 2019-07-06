class CreateScratchpads < ActiveRecord::Migration[6.0]
  def change
    create_table :scratchpads do |t|
      t.bigint :account_id, null: false
      t.bigint :creator_id, null: false
      t.string :name, null: false
      t.json :document, null: false
      t.integer :open_todo_count, null: false, default: 0
      t.integer :closed_todo_count, null: false, default: 0
      t.integer :total_todo_count, null: false, default: 0
      t.string :access_mode, null: false
      t.datetime :closest_future_deadline
      t.datetime :discarded_at

      t.timestamps
    end

    add_foreign_key :scratchpads, :accounts
    add_foreign_key :scratchpads, :users, column: :creator_id
  end
end
