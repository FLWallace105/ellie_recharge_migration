class CreateAddress < ActiveRecord::Migration[5.2]
  def up
    create_table :addresses do |t|
      
      t.string :address_id
      t.string :customer_id
      t.datetime :created_at
      t.datetime :updated_at
      t.string :address1
      t.string :address2
      t.string :city
      t.string :province
      t.string :first_name
      t.string :last_name
      t.string :zip
      t.string :company
      t.string :phone
      t.string :country
      t.text :cart_note
      t.jsonb :original_shipping_lines
      t.jsonb :cart_attributes
      t.jsonb :note_attributes
      t.string :discount_id
     
      
    end
    
    
  end

  def down
    
    drop_table :addresses
    
    
  end
end
