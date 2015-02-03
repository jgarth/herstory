class CreateShipments < ActiveRecord::Migration
  def change
    create_table :shipments do |t|
      t.integer :pieces
    end
  end
end
