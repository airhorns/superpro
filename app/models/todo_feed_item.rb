# == Schema Information
#
# Table name: todo_feed_items
#
#  id               :text
#  access_mode      :string
#  name             :string
#  started_at       :datetime
#  todo_source_type :text
#  created_at       :datetime
#  updated_at       :datetime
#  account_id       :bigint(8)
#  creator_id       :bigint(8)
#  todo_source_id   :bigint(8)
#

class TodoFeedItem < ApplicationRecord
  include AccountScoped

  belongs_to :todo_source, polymorphic: true

  def readonly?
    true
  end
end
