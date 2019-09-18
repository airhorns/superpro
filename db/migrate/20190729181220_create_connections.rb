# frozen_string_literal: true

class CreateConnections < ActiveRecord::Migration[6.0]
  def change
    create_table :connections do |t|
      t.bigint :account_id, null: false
      t.bigint :integration_id, null: false
      t.string :integration_type, null: false
      t.boolean :enabled, null: false, default: true
      t.string :display_name, null: false
      t.string :strategy, null: false

      t.timestamps
    end

    add_foreign_key :connections, :accounts
  end
end
