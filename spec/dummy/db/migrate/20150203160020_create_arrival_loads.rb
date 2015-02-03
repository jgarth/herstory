class CreateArrivalLoads < ActiveRecord::Migration
  def change
    create_table :arrival_loads do |t|
      t.integer :pieces_checkedin
      t.references :arrival
      t.references :shipment
    end
  end
end
