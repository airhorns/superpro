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

require "test_helper"

class TodoFeedItemTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
