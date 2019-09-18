# frozen_string_literal: true

class CreatePlaidTransactions < ActiveRecord::Migration[6.0]
  def change
    create_table :plaid_transactions do |t|
      t.bigint :account_id, null: false
      t.bigint :plaid_item_id, null: false
      t.string :plaid_account_identifier, null: false
      t.string :plaid_transaction_identifier, null: false
      t.string :category, array: true
      t.string :category_id
      t.string :transaction_type, null: false
      t.string :name, null: false
      t.string :amount, null: false
      t.string :iso_currency_code
      t.string :unofficial_currency_code
      t.date :date, null: false

      t.timestamps

      t.index :plaid_transaction_identifier, unique: true
    end

    add_foreign_key :plaid_transactions, :accounts
    add_foreign_key :plaid_transactions, :plaid_items
  end
end
