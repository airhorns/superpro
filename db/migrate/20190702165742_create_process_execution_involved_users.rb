class CreateProcessExecutionInvolvedUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :process_execution_involved_users do |t|
      t.bigint :account_id, null: false
      t.bigint :process_execution_id, null: false
      t.bigint :user_id, null: false

      t.timestamps
    end

    add_foreign_key :process_execution_involved_users, :accounts
    add_foreign_key :process_execution_involved_users, :process_executions
    add_foreign_key :process_execution_involved_users, :users
  end
end
