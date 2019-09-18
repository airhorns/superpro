# frozen_string_literal: true

class CreatePlaidItems < ActiveRecord::Migration[6.0]
  def change
    create_table :plaid_items do |t|
      t.bigint :account_id, null: false
      t.bigint :creator_id, null: false
      t.string :access_token, null: false
      t.bigint :item_id, null: false
      t.boolean :initial_update_complete, null: false, default: false

      t.timestamps
    end

    add_foreign_key :plaid_items, :accounts
    add_foreign_key :plaid_items, :users, column: :creator_id
  end
end
