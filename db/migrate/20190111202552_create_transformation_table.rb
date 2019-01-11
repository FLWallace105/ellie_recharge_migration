class CreateTransformationTable < ActiveRecord::Migration[5.2]
  def up
    create_table :product_transformations do |t|

      t.string :production_title
      t.string :production_product_id
      t.string :staging_product_id
      t.string :staging_variant_id
      t.string :staging_sku
    end

  end

  def down
    drop_table :product_transformations

  end
end
