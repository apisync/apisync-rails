class CreateProducts < ActiveRecord::Migration[5.1]
  def change
    create_table :products, id: :uuid do |t|
      t.string :title
      t.string :description
      t.string :category
      t.boolean :active
      t.string :brand
      t.string :model
      t.string :permalink
      t.integer :price_in_cents

      t.timestamps
    end
  end
end
