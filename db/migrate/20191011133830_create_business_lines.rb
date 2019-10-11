# frozen_string_literal: true
class CreateBusinessLines < ActiveRecord::Migration[6.0]
  def change
    create_table :business_lines do |t|
      t.bigint :account_id, null: false
      t.string :name, null: false
      t.bigint :creator_id, null: false

      t.timestamps
    end

    add_foreign_key :business_lines, :accounts
    add_foreign_key :business_lines, :users, column: :creator_id
  end
end
