# frozen_string_literal: true

class AddCreatedAtIndexToSingerSyncAttempts < ActiveRecord::Migration[6.0]
  def change
    add_index :singer_sync_attempts, :created_at
  end
end
