class AddInitialMetricsToProcessExecutions < ActiveRecord::Migration[6.0]
  def change
    change_table :process_executions, bulk: true do |t|
      t.datetime :closest_future_deadline
      t.integer :open_todo_count, null: false, default: 0
      t.integer :closed_todo_count, null: false, default: 0
      t.integer :total_todo_count, null: false, default: 0
    end
  end
end
