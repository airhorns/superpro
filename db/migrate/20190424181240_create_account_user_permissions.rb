class CreateAccountUserPermissions < ActiveRecord::Migration[6.0]
  def change
    create_table :account_user_permissions do |t|
      t.bigint :account_id, null: false
      t.bigint :user_id, null: false

      t.timestamps
    end

    add_foreign_key :account_user_permissions, :accounts
    add_foreign_key :account_user_permissions, :users
  end
end
