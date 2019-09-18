# frozen_string_literal: true

class CreateAccounts < ActiveRecord::Migration[6.0]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.bigint :creator_id, null: false
      t.datetime :discarded_at
      t.index :discarded_at

      t.timestamps
    end

    add_foreign_key :accounts, :users, column: :creator_id
  end
end
