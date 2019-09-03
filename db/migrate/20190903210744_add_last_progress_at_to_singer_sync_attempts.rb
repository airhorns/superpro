class AddLastProgressAtToSingerSyncAttempts < ActiveRecord::Migration[6.0]
  def change
    add_column :singer_sync_attempts, :last_progress_at, :datetime, null: false, default: "2019-01-01 01:01:00"
  end
end
