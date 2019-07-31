class CreateShopifyShops < ActiveRecord::Migration[6.0]
  def change
    create_table :shopify_shops do |t|
      t.string :shopify_domain, null: false
      t.string :api_key, null: false
      t.string :password, null: false
      t.string :name, null: false
      t.bigint :shop_id, null: false
      t.bigint :account_id, null: false
      t.bigint :creator_id, null: false

      t.timestamps
    end

    add_foreign_key :shopify_shops, :accounts
    add_foreign_key :shopify_shops, :users, column: :creator_id
    add_index :shopify_shops, [:account_id, :shopify_domain], unique: true
  end
end
