class AddBusinessEpochToAccounts < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :business_epoch, :datetime, default: "2018-01-01 01:01:00.0"
  end
end
