class CreateSeries < ActiveRecord::Migration[6.0]
  def change
    create_table :series do |t|
      t.bigint :account_id, null: false
      t.string :x_type, null: false
      t.string :y_type, null: false
      t.string :currency, null: true
      t.bigint :creator_id, null: false

      t.timestamps
    end

    add_foreign_key :series, :accounts
    add_foreign_key :series, :users, column: :creator_id

    change_table :budget_lines do |t|
      t.bigint :series_id, null: false
    end

    add_foreign_key :budget_lines, :series
  end
end
