class CreateSingerSyncStates < ActiveRecord::Migration[6.0]
  def change
    create_table :singer_sync_states do |t|
      t.bigint :account_id, null: false
      t.bigint :connection_id, null: false
      t.json :state, null: false

      t.timestamps
    end

    add_foreign_key :singer_sync_states, :accounts
    add_foreign_key :singer_sync_states, :connections
  end
end
