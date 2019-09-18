# frozen_string_literal: true

class AddDiscardedAtToConnection < ActiveRecord::Migration[6.0]
  def change
    add_column :connections, :discarded_at, :datetime
  end
end
