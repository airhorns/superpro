class CreateCells < ActiveRecord::Migration[6.0]
  def change
    create_table :cells do |t|
      t.bigint :account_id, null: false
      t.bigint :series_id, null: false

      t.numeric :x_number
      t.string :x_string
      t.timestamp :x_datetime
      t.integer :y_money_subunits
      t.numeric :y_number
      t.string :y_string

      t.timestamps
    end

    add_foreign_key :cells, :accounts
    add_foreign_key :cells, :series
    add_index :cells, [:account_id, :series_id]
  end
end
