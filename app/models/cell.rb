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

class Cell < ApplicationRecord
  include AccountScoped

  belongs_to :series
  monetize :y_money_subunits, as: "y_money", with_currency: ->(cell) { cell.series.currency }, allow_nil: true
  validates :x, presence: true
  validates :y, presence: true

  def x
    self["x_#{series.x_type}"]
  end

  def y
    if series.y_type == "money"
      self.y_money  # money-rails doesn't register the money object accessor as an attribute, so we have to just invoke the method
    else
      self["y_#{series.y_type}"]
    end
  end
end
