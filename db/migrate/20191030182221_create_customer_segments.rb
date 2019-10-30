# frozen_string_literal: true
class CreateCustomerSegments < ActiveRecord::Migration[6.0]
  def change
    create_table :customer_segments do |t|
      t.bigint :account_id, null: false
      t.string :name, null: false
      t.text :description
      t.string :strategy, null: false
      t.bigint :creator_id, null: false

      t.jsonb :rules

      t.timestamps
    end

    add_foreign_key :customer_segments, :accounts
    add_foreign_key :customer_segments, :users, column: :creator_id
  end
end
