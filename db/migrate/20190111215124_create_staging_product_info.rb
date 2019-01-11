class CreateStagingProductInfo < ActiveRecord::Migration[5.2]
  def up
    #product_id,variant_id,sku,var_title,prod_title
    create_table :staging_product_info do |t|

      t.string :staging_product_title
      t.string :staging_variant_title
      t.string :staging_product_id
      t.string :staging_variant_id
      t.string :staging_sku

      
    end


  end

  def down
    drop_table :staging_product_info

  end

end
