class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.references :newly_associated_object, polymorphic: true
      t.references :previously_associated_object, polymorphic: true
      t.references :parent, polymorphic: true
      t.references :user
      t.string :type
      t.string :previous_value
      t.string :new_value
      t.timestamps null: false
    end

    add_index :events, [:parent_id, :parent_type]
    add_index :events, :user_id
  end
end
