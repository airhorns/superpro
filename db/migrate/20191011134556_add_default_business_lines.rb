# frozen_string_literal: true
class AddDefaultBusinessLines < ActiveRecord::Migration[6.0]
  def up
    Account.find_each do |account|
      account.business_lines.create!(name: "Direct to Consumer", creator_id: account.creator_id)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Can't undo maintenance task"
  end
end
