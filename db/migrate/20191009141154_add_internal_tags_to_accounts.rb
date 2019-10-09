# frozen_string_literal: true
class AddInternalTagsToAccounts < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :internal_tags, :string, array: true, null: false, default: []
  end
end
