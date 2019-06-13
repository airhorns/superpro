class CreateCellDetails < ActiveRecord::Migration[6.0]
  def change
    create_view :cell_details
  end
end
