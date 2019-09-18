# frozen_string_literal: true

class CreatePlaidItemAccounts < ActiveRecord::Migration[6.0]
  def change
    create_table :plaid_item_accounts do |t|
      t.bigint :account_id, null: false
      t.bigint :plaid_item_id, null: false
      t.string :plaid_account_identifier, null: false
      t.string :name, null: false
      t.string :type, null: false
      t.string :subtype, null: false

      t.timestamps
    end

    add_foreign_key :plaid_item_accounts, :accounts
    add_foreign_key :plaid_item_accounts, :plaid_items
  end
end
