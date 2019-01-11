#migration.rb
require 'dotenv'
Dotenv.load
require 'httparty'
require 'resque'
require 'sinatra'
require 'active_record'
require "sinatra/activerecord"
require_relative 'models/model'
#require_relative 'resque_helper'
#require 'pry'

module MigrateRecharge
  class Downloader
    def initialize
      Dotenv.load
      recharge_regular = ENV['RECHARGE_ACCESS_TOKEN']
      recharge_staging = ENV['STAGING_RECHARGE_ACCESS_TOKEN']
      
      @my_header = {
        "X-Recharge-Access-Token" => recharge_regular
      }
      @my_change_header = {
        "X-Recharge-Access-Token" => recharge_regular,
        "Accept" => "application/json",
        "Content-Type" =>"application/json"
      }
      @my_staging_header = {
        "X-Recharge-Access-Token" => recharge_staging
      }
      @my_staging_change_header = {
        "X-Recharge-Access-Token" => recharge_staging,
        "Accept" => "application/json",
        "Content-Type" =>"application/json"
      }

    end


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

    def download_addresses
        puts "Howdy"

        Address.delete_all
        ActiveRecord::Base.connection.reset_pk_sequence!('addresses')

        start = Time.now    
        page_size = 250
        num_pages = 50000
        1.upto(num_pages) do |page|
            addresses = HTTParty.get("https://api.rechargeapps.com/addresses?limit=250&page=#{page}", :headers => @my_header)
            puts "Page = #{page}"
            puts "--------------"
            puts addresses
            puts "---------------"
            #exit
             
            my_addresses = addresses.parsed_response['addresses']
            recharge_limit = addresses.response["x-recharge-limit"]
            if  addresses['addresses'] == []
                puts "Page is #{page}"
                puts "Exiting"
                break
            else
              #process addresses
              my_addresses.each do |myadd|
                puts "******************"
                puts myadd.inspect
                puts "******************"
                local_add = Address.create(address_id: myadd['id'], customer_id: myadd['customer_id'], created_at: myadd['created_at'], updated_at: myadd['updated_at'], address1: myadd['address1'], address2: myadd['address2'], city: myadd['city'], province: myadd['province'], first_name: myadd['first_name'], last_name: myadd['last_name'], zip: myadd['zip'], company: myadd['company'], phone: myadd['phone'], country: myadd['country'], cart_note: myadd['cart_note'], original_shipping_lines: myadd['original_shipping_lines'], cart_attributes: myadd['cart_attributes'], note_attributes: myadd['note_attributes'], discount_id: myadd['discount_id'])

              end


            end
            determine_limits(recharge_limit, 0.65)
            
            
        end
        puts "All done now"

    end



    def test_checkout

      puts "Starting test subscription"
      #POST /checkouts/
      body  = {
        "checkout": {
    
                 "line_items": [
                {
                    "charge_interval_frequency": 1,
                    "cutoff_day_of_month": nil,
                    "cutoff_day_of_week": nil,
                    "expire_after_specific_number_of_charges": nil,
                    "fulfillment_service": "manual",
                    "grams": 0,
                    "line_price": "39.95",
                    "order_day_of_month": nil,
                    "order_day_of_week": nil,
                    "order_interval_frequency": 1,
                    "order_interval_unit_type": "month",
                    "price": "39.95",
                    "product_id": 1663704662067,
                    "properties": { "leggings": "XS", "product_collection": "True Blue - 3 Items", "tops": "XS", "sports-bra": "XS", "sports-jacket": "S"},
                    "quantity": 1,
                    "requires_shipping": true,
                    "sku": "764204268269",
                    "taxable": true,
                    "title": "True Blue - 3 Items",
                    "variant_id": 15983728099379,
                    "variant_title": "Default Title",
                    "vendor": "Ellie"
                }
            ],
            "shipping_address": {
               "address1": "5553 B Bandini Blvd",
               "address2": nil,
               "city": "Bell",
               "company": "Fambrands LLC",
               "country": "United States",
               "first_name": "Funky2",
               "last_name": "Chicken2",
               "phone": "5557778888",
               "province": "California",
               "zip": "90201"
           },
           "email":"funky_chicken2@gmail.com"
        }
    }.to_json
    
    #@my_staging_change_header
    #POST /checkouts/
    new_subscription = HTTParty.post("https://api.rechargeapps.com/checkouts/", :headers => @my_staging_change_header, :body => body)
    puts new_subscription.inspect
    my_token = new_subscription.parsed_response['checkout']['token']
    data ={
      "checkout_charge": {
          "free": false,
          "payment_processor": "stripe",
          "payment_token": "tok_visa"
          }
        }.to_json

  my_processing = HTTParty.post("https://api.rechargeapps.com/checkouts/#{my_token}/charge", :headers => @my_staging_change_header, :body => data)
  puts my_processing.inspect

    end

    def process_test_sub
      #POST /checkouts/<checkout_token>/charge
      #"token"=>"d4b2871f0f9c4434a8a0317b2ae00fad"

      #note here is response from above method
      #Starting test subscription
      #<HTTParty::Response:0x7ff4f63be2a8 parsed_response={"checkout"=>{"applied_discount"=>nil, "billing_address"=>nil, "buyer_accepts_marketing"=>false, "completed_at"=>nil, "created_at"=>"2019-01-10T14:51:26.864619+00:00", "discount_code"=>nil, "email"=>"funky_chicken@gmail.com", "line_items"=>[{"charge_interval_frequency"=>1, "cutoff_day_of_month"=>nil, "cutoff_day_of_week"=>nil, "expire_after_specific_number_of_charges"=>nil, "fulfillment_service"=>"manual", "grams"=>0, "image"=>"//cdn.shopify.com/s/files/1/1904/6091/products/181205_EllieStudio34416_33_982190c1-0b6d-450d-965a-2fc6f050beed_small.jpg?v=1546889446", "line_price"=>"39.95", "order_day_of_month"=>nil, "order_day_of_week"=>nil, "order_interval_frequency"=>1, "order_interval_unit_type"=>"month", "price"=>"39.95", "product_id"=>1663704662067, "properties"=>{"leggings"=>"XS", "product_collection"=>"True Blue - 3 Items", "sports-bra"=>"XS", "sports-jacket"=>"S", "tops"=>"XS"}, "quantity"=>1, "requires_shipping"=>true, "sku"=>"764204268269", "taxable"=>true, "title"=>"True Blue - 3 Items", "variant_id"=>15983728099379, "variant_title"=>"Default Title", "vendor"=>"Ellie"}], "note"=>nil, "note_attributes"=>nil, "payment_processor"=>nil, "payment_processor_customer_id"=>nil, "payment_processor_transaction_id"=>nil, "phone"=>nil, "requires_shipping"=>true, "shipping_address"=>{"address1"=>"5553 B Bandini Blvd", "address2"=>nil, "city"=>"Bell", "company"=>"Fambrands LLC", "country"=>"United States", "first_name"=>"Funky", "last_name"=>"Chicken", "phone"=>"5557778888", "province"=>"California", "zip"=>"90201"}, "shipping_line"=>nil, "shipping_rate"=>nil, "subtotal_price"=>"39.95", "tax_lines"=>[], "taxes_included"=>false, "token"=>"d4b2871f0f9c4434a8a0317b2ae00fad", "total_price"=>"39.95", "total_tax"=>"0.00", "updated_at"=>"2019-01-10T14:51:26.864628+00:00"}}, @response=#<Net::HTTPOK 200 OK readbody=true>, @headers={"server"=>["nginx/1.14.0"], "date"=>["Thu, 10 Jan 2019 19:51:26 GMT"], "content-type"=>["application/json"], "content-length"=>["1683"], "connection"=>["close"], "x-recharge-limit"=>["1/40"], "set-cookie"=>["session=eyJfcGVybWFuZW50Ijp0cnVlfQ.Dxkzvg.0vlyeJcGT0h3XViqS5cFxNrtwFU; Domain=.rechargeapps.com; Expires=Sun, 10-Feb-2019 19:51:26 GMT; HttpOnly; Path=/"], "x-request-id"=>["c6675e80b8ee75a9c7a3b3b86e14c625"]}>





      data ={
        "checkout_charge": {
            "free": false,
            "payment_processor": "stripe",
            "payment_token": "tok_visa"
            }
          }.to_json

    my_processing = HTTParty.post("https://api.rechargeapps.com/checkouts/d4b2871f0f9c4434a8a0317b2ae00fad/charge", :headers => @my_staging_change_header, :body => data)
    puts my_processing.inspect

    end

    
  end
end