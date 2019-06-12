# == Schema Information
#
# Table name: cells
#
#  id               :bigint(8)        not null, primary key
#  x_datetime       :datetime
#  x_number         :decimal(, )
#  x_string         :string
#  y_money_subunits :integer
#  y_number         :decimal(, )
#  y_string         :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint(8)        not null
#  series_id        :bigint(8)        not null
#
# Indexes
#
#  index_cells_on_account_id_and_series_id  (account_id,series_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (series_id => series.id)
#

require "test_helper"

class CellTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
