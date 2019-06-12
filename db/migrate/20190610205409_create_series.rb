class CreateSeries < ActiveRecord::Migration[6.0]
  def change
    create_table :series do |t|
      t.bigint :account_id, null: false
      t.string :scenario, null: false
      t.string :x_type, null: false
      t.string :y_type, null: false
      t.string :currency, null: true
      t.bigint :creator_id, null: false

      t.timestamps
    end

    add_foreign_key :series, :accounts
    add_foreign_key :series, :users, column: :creator_id
    add_index :series, [:account_id, :scenario]
  end
end
