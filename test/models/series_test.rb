# == Schema Information
#
# Table name: series
#
#  id         :bigint(8)        not null, primary key
#  currency   :string
#  scenario   :string           not null
#  x_type     :enum             not null
#  y_type     :enum             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint(8)        not null
#  creator_id :bigint(8)        not null
#
# Indexes
#
#  index_series_on_account_id_and_scenario  (account_id,scenario)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (creator_id => users.id)
#

require 'test_helper'

class SeriesTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
