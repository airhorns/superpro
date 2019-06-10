# == Schema Information
#
# Table name: series
#
#  id                 :bigint(8)        not null, primary key
#  currency           :string
#  domain_type        :string           not null
#  range_type         :string           not null
#  scenario           :string           not null
#  series_domain_type :string           not null
#  series_range_type  :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :bigint(8)        not null
#  creator_id         :bigint(8)        not null
#

require 'test_helper'

class SeriesTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
