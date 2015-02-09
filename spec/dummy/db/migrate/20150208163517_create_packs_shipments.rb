class CreatePacksShipments < ActiveRecord::Migration
  def change
    create_table :packs_shipments, id: false do |t|
      t.belongs_to :pack, index: true
      t.belongs_to :shipment, index: true
    end
  end
end
