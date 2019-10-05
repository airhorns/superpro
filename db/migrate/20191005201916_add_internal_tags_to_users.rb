# frozen_string_literal: true
class AddInternalTagsToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :internal_tags, :string, array: true, null: false, default: []
  end
end
