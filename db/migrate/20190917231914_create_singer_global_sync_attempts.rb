class CreateSingerGlobalSyncAttempts < ActiveRecord::Migration[6.0]
  def change
    create_table :singer_global_sync_attempts do |t|
      t.string :key, null: false
      t.string :failure_reason
      t.datetime :finished_at
      t.datetime :last_progress_at
      t.datetime :started_at
      t.boolean :success

      t.timestamps
    end
  end
end
