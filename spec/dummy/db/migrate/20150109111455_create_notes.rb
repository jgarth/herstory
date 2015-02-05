class CreateNotes < ActiveRecord::Migration
  def change
    create_table :notes do |t|
      t.references :user, index: true
      t.references :parent, index: true, polymorphic: true
      t.text :text
      t.timestamps null: false
    end
  end
end
