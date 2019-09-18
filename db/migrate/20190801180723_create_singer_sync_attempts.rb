# frozen_string_literal: true

class CreateSingerSyncAttempts < ActiveRecord::Migration[6.0]
  def change
    create_table :singer_sync_attempts do |t|
      t.bigint :account_id, null: false
      t.bigint :connection_id, null: false
      t.boolean :success, null: true
      t.datetime :started_at, null: false
      t.datetime :finished_at, null: true
      t.string :failure_reason, null: true

      t.timestamps
    end

    add_foreign_key :singer_sync_attempts, :accounts
    add_foreign_key :singer_sync_attempts, :connections
  end
end
