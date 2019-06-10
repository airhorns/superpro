class CreateSeries < ActiveRecord::Migration[6.0]
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
          CREATE TYPE series_domain_type AS ENUM ('datetime', 'number', 'string');
          CREATE TYPE series_range_type AS ENUM ('money', 'number', 'string');
        SQL
      end
      dir.down do
        execute <<-SQL
          DROP TYPE series_domain_type;
          DROP TYPE series_range_type;
        SQL
      end
    end

    create_table :series do |t|
      t.bigint :account_id, null: false
      t.string :scenario, null: false
      t.string :domain_type, :series_domain_type, null: false
      t.string :range_type, :series_range_type, null: false
      t.string :currency, null: true
      t.bigint :creator_id, null: false

      t.timestamps
    end
  end
end
