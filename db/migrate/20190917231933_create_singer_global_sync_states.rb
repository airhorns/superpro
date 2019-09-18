class CreateSingerGlobalSyncStates < ActiveRecord::Migration[6.0]
  def change
    create_table :singer_global_sync_states do |t|
      t.string :key, null: false, unique: true
      t.jsonb :state, null: false

      t.timestamps
    end
  end
end
