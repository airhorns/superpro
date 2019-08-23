class CreateGoogleAnalyticsCredentials < ActiveRecord::Migration[6.0]
  def change
    create_table :google_analytics_credentials do |t|
      t.bigint :account_id, null: false
      t.bigint :creator_id, null: false
      t.string :token, null: false
      t.string :refresh_token, null: false
      t.datetime :expires_at, null: true
      t.string :grantor_name, null: false
      t.string :grantor_email, null: false
      t.boolean :configured, null: false, default: false
      t.bigint :view_id, null: true
      t.string :view_name, null: true
      t.bigint :property_id, null: true
      t.string :property_name, null: true
      t.bigint :ga_account_id, null: true
      t.string :ga_account_name, null: true

      t.timestamps
    end

    add_foreign_key :google_analytics_credentials, :accounts
    add_foreign_key :google_analytics_credentials, :users, column: :creator_id
  end
end
