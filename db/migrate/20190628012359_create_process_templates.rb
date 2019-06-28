class CreateProcessTemplates < ActiveRecord::Migration[6.0]
  def change
    create_table :process_templates do |t|
      t.bigint :account_id, null: false
      t.bigint :creator_id, null: false
      t.string :name, null: false
      t.json :document, null: false

      t.datetime :discarded_at
      t.timestamps
    end

    add_foreign_key :process_templates, :accounts
    add_foreign_key :process_templates, :users, column: :creator_id
  end
end
