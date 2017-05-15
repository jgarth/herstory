class CreateShipments < ActiveRecord::Migration[4.2]
  def change
    create_table :shipments do |t|
      t.integer :pieces
    end
  end
end
