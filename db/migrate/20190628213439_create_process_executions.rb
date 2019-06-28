class CreateProcessExecutions < ActiveRecord::Migration[6.0]
  def change
    create_table :process_executions do |t|
      t.bigint :account_id, null: false
      t.bigint :creator_id, null: false
      t.bigint :owner_id, null: false
      t.bigint :process_template_id
      t.string :name, null: false
      t.json :document, null: false
      t.datetime :started_at
      t.datetime :discarded_at

      t.timestamps
    end

    add_foreign_key :process_executions, :accounts
    add_foreign_key :process_executions, :process_templates
    add_foreign_key :process_executions, :users, column: :creator_id
    add_foreign_key :process_executions, :users, column: :owner_id
  end
end
