# frozen_string_literal: true

class CreateFacebookAdAccounts < ActiveRecord::Migration[6.0]
  def change
    create_table :facebook_ad_accounts do |t|
      t.bigint :account_id, null: false
      t.bigint :creator_id, null: false

      t.boolean :configured, null: false, default: false
      t.string :access_token, null: false
      t.datetime :expires_at, null: true
      t.string :grantor_id, null: false
      t.string :grantor_name, null: false

      t.string :fb_account_id, null: true
      t.string :fb_account_name, null: true

      t.timestamps
    end

    add_foreign_key :facebook_ad_accounts, :accounts
    add_foreign_key :facebook_ad_accounts, :users, column: :creator_id
  end
end
