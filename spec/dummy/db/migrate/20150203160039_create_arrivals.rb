class CreateArrivals < ActiveRecord::Migration[4.2]
  def change
    create_table :arrivals do |t|
      t.integer :number_of_trucks
    end
  end
end
