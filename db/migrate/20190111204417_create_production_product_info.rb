class CreateProductionProductInfo < ActiveRecord::Migration[5.2]
  def up
    create_table :production_product_info do |t|

      t.string :production_title
      t.string :production_product_id
      
    end
  end

  def down
    drop_table :production_product_info
  end
end
