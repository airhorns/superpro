class CreateSeries < ActiveRecord::Migration[6.0]
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
          CREATE TYPE series_x_type AS ENUM ('datetime', 'number', 'string');
          CREATE TYPE series_y_type AS ENUM ('money', 'number', 'string');
        SQL
      end
      dir.down do
        execute <<-SQL
          DROP TYPE series_x_type;
          DROP TYPE series_y_type;
        SQL
      end
    end

    create_table :series do |t|
      t.bigint :account_id, null: false
      t.string :scenario, null: false
      t.column :x_type, :series_x_type, null: false
      t.column :y_type, :series_y_type, null: false
      t.string :currency, null: true
      t.bigint :creator_id, null: false

      t.timestamps
    end

    add_foreign_key :series, :accounts
    add_foreign_key :series, :users, column: :creator_id
    add_index :series, [:account_id, :scenario]
  end
end
