#resque_helper
require 'dotenv'
require 'active_support/core_ext'
require 'sinatra/activerecord'
require 'httparty'
require_relative 'models/model'


Dotenv.load

module ResqueHelper

    def determine_limits(recharge_header, limit)
        puts "recharge_header = #{recharge_header}"
        my_numbers = recharge_header.split("/")
        my_numerator = my_numbers[0].to_f
        my_denominator = my_numbers[1].to_f
        my_limits = (my_numerator/ my_denominator)
        puts "We are using #{my_limits} % of our API calls"
        if my_limits > limit
            puts "Sleeping 10 seconds"
            sleep 10
        else
            puts "not sleeping at all"
        end
  
      end



    def transform_properties(my_props)
        #{ "leggings": "XS", "product_collection": "True Blue - 3 Items", "tops": "XS", "sports-bra": "XS", "sports-jacket": "S"}
        properties = {}
        my_props.each do |prop|
          #puts prop.inspect
          #puts "#{prop['name']} #{prop['value']}"
          properties[prop['name']] = prop['value']
        end
        return properties
    
      end

    def transform_product_id(product_id)
        #stub here
        my_local_prod_var = ProductTransformation.find_by_production_product_id(product_id)
        if !my_local_prod_var.nil?
            stuff_to_return = {"staging_product_id" => my_local_prod_var.staging_product_id, "staging_variant_id" => my_local_prod_var.staging_variant_id, "staging_sku" => my_local_prod_var.staging_sku}
            return stuff_to_return
        else
            puts "Can't find transformation data"
            stuff_to_return = {"staging_product_id" => "nothing", "staging_variant_id" => "nothing", "staging_sku" => "nothing"}

        end

    end


    def migrate_checkout(params)
        line_price = (params['quantity'].to_f)*(params['price'].to_f).round(2)
        puts params.inspect
        #exit
        recharge_change_header = params['recharge_change_header']

        puts "Starting Migration of this subscription via checkout api ..."
        #POST /checkouts/
        body  = {
          "checkout": {
      
                   "line_items": [
                  {
                      "charge_interval_frequency": params['charge_interval_frequency'],
                      "cutoff_day_of_month": nil,
                      "cutoff_day_of_week": nil,
                      "expire_after_specific_number_of_charges": nil,
                      "fulfillment_service": "manual",
                      "grams": 0,
                      "line_price": line_price,
                      "order_day_of_month": nil,
                      "order_day_of_week": nil,
                      "order_interval_frequency": params['order_interval_frequency'],
                      "order_interval_unit_type": params['order_interval_unit'],
                      "price": params['price'],
                      "product_id": params['product_id'],
                      "properties": params['my_properties'],
                      "quantity": params['quantity'],
                      "requires_shipping": true,
                      "sku": params['sku'],
                      "taxable": true,
                      "title": params['product_title'],
                      "variant_id": params['variant_id'],
                      "variant_title": "Default Title",
                      "vendor": "Ellie"
                  }
              ],
              "shipping_address": {
                 "address1": params['address1'],
                 "address2": params['address2'],
                 "city": params['city'],
                 "company": params['company'],
                 "country": params['country'],
                 "first_name": params['first_name'],
                 "last_name": params['last_name'],
                 "phone": params['phone'],
                 "province": params['province'],
                 "zip": params['zip']
             },
             "email": params['email']
          }
      }.to_json
      puts body
      
      #exit
      
      #@my_staging_change_header
      #POST /checkouts/
      new_subscription = HTTParty.post("https://api.rechargeapps.com/checkouts/", :headers => recharge_change_header, :body => body)
      puts new_subscription.inspect
      recharge_limit = new_subscription.response["x-recharge-limit"]
      determine_limits(recharge_limit, 0.65)
      sleep 3
      my_token = new_subscription.parsed_response['checkout']['token']
      data ={
        "checkout_charge": {
            "free": false,
            "payment_processor": "stripe",
            "payment_token": "tok_visa"
            }
          }.to_json
  
       my_processing = HTTParty.post("https://api.rechargeapps.com/checkouts/#{my_token}/charge", :headers => recharge_change_header, :body => data)
        puts my_processing.inspect
       recharge_limit = my_processing.response["x-recharge-limit"]
       determine_limits(recharge_limit, 0.65)
  
      end
    



    def migrate_subscriptions(params)
        puts "Starting background job ..."
        puts params.inspect
        recharge_change_header = params['recharge_change_header']
        my_now = Time.now

        my_subs = SubscriptionsMigrated.where(migrated_to_staging: false)
        my_subs.each do |sub|
            puts sub.inspect
            my_properties = transform_properties(sub.raw_line_item_properties)
            my_prod_var = transform_product_id(sub.shopify_product_id)
            puts my_properties
            if my_prod_var['staging_product_id'] != "nothing"
                puts my_prod_var
                customer_id = sub.customer_id
                puts "my customer_id = #{customer_id}"
                my_customer = Customer.find_by_customer_id(customer_id)
                address1 = "asd"
                address2 = "asd"
                company = "asd"
                phone = "5554447777"
                if !my_customer.billing_address1.nil? && my_customer.billing_address1 != ""
                    address1 = my_customer.billing_address1
                end
                if !my_customer.billing_address2.nil? && my_customer.billing_address2 != ""
                    address2 = my_customer.billing_address2
                end
                if !my_customer.billing_company.nil? && my_customer.billing_company != ""
                    company = my_customer.billing_company
                end
                if !my_customer.billing_phone.nil? && my_customer.billing_phone != ""
                    phone = my_customer.billing_phone
                end

                puts "Constructing params"
                params = {"my_properties" => my_properties, "product_id" => my_prod_var['staging_product_id'], "variant_id" => my_prod_var['staging_variant_id'], "sku" => my_prod_var['staging_sku'], "charge_interval_frequency" => sub.charge_interval_frequency, "price" => sub.price, "quantity" => sub.quantity, "order_interval_frequency" => sub.order_interval_frequency, "order_interval_unit" => sub.order_interval_unit, "product_title" => sub.product_title, "email" => my_customer.email, "address1" => address1, "address2" => address2, "city" => my_customer.billing_city, "company" => company, "country" => my_customer.billing_country, "first_name" => my_customer.first_name, "last_name" => my_customer.last_name, "phone" => my_customer.billing_phone, "province" => my_customer.billing_province, "zip" => my_customer.billing_zip, "recharge_change_header" => recharge_change_header}
                migrate_checkout(params)
                sub.migrated_to_staging = true
                time_updated = DateTime.now
                time_updated_str = time_updated.strftime("%Y-%m-%d %H:%M:%S")
                sub.processed_at = time_updated_str
                sub.save!

                
            else
                puts "Can't migrate this one"
                next
            end

            my_current = Time.now
            duration = (my_current - my_now).ceil
            puts "Been running #{duration} seconds"
            #Resque.logger.info "Been running #{duration} seconds"

            if duration > 480
                #Resque.logger.info "Been running more than 8 minutes must exit"
                puts "Stopping run for now"
                break
            end
            

        end

        puts "All done migrating subscriptions"

    end



end