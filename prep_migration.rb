#migration.rb
require 'dotenv'
Dotenv.load
require 'httparty'
require 'resque'
require 'sinatra'
require 'active_record'
require "sinatra/activerecord"
require_relative 'models/model'
require_relative 'resque_helper'
#require 'pry'

module PrepMigration
  class Setup
    
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

  def setup_transformations_table
    puts "starting load"
    ProductTransformation.delete_all
      # Now reset index
    ActiveRecord::Base.connection.reset_pk_sequence!('product_transformations')

    CSV.foreach('transformation.csv', :encoding => 'ISO-8859-1', :headers => true) do |row|
      puts row['production_title']
      my_transformation = ProductTransformation.create(production_title: row['production_title'])
    end

    ProductionProductInfo.delete_all
    ActiveRecord::Base.connection.reset_pk_sequence!('production_product_info')
    CSV.foreach('raw_production_data.csv', :encoding => 'ISO-8859-1', :headers => true) do |row|
      puts row.inspect
      my_production_product_info = ProductionProductInfo.create(production_title: row['title'], production_product_id: row['product_id'])
      
    end
    


    my_transformations = ProductTransformation.all
    my_transformations.each do |myt|
      puts myt.production_title
      my_production_product_info = ProductionProductInfo.find_by_production_title(myt.production_title)
      if !my_production_product_info.nil?
        puts my_production_product_info.inspect
        myt.production_product_id = my_production_product_info.production_product_id
        myt.save!
      else
        puts "not found"
      end
      #myt.production_product_id = my_production_product_info.production_product_id
      #myt.save!

    end

    puts "All done setting up tables"

  end


  def setup_staging_product_info
    puts "Starting Staging Product info"
    StagingProductInfo.delete_all
    ActiveRecord::Base.connection.reset_pk_sequence!('staging_product_info')
    CSV.foreach('raw_staging_data.csv', :encoding => 'ISO-8859-1', :headers => true) do |row|
      puts row.inspect
      my_staging_prod_info = StagingProductInfo.create(staging_product_id: row['product_id'], staging_variant_id: row['variant_id'], staging_sku: row['sku'], staging_variant_title: row['var_title'], staging_product_title: row['prod_title'])
    end
    puts "Done setting up stating_product_info table"

    my_transformations = ProductTransformation.all
    my_transformations.each do |myt|
      puts myt.production_title
      my_staging_product_info = StagingProductInfo.where("staging_product_title = ?", myt.production_title).first
      if !my_staging_product_info.nil?
        puts my_staging_product_info.inspect
        myt.staging_product_id = my_staging_product_info.staging_product_id
        myt.staging_variant_id = my_staging_product_info.staging_variant_id
        myt.staging_sku = my_staging_product_info.staging_sku
        myt.save!
      else
        puts "not found"
      end


    end




  end

  def reload_product_transformations
    puts "Starting reload product_transformations table from CSV"
    ProductTransformation.delete_all
    ActiveRecord::Base.connection.reset_pk_sequence!('product_transformations')
    CSV.foreach('product_transformations_export.csv', :encoding => 'ISO-8859-1', :headers => true) do |row|
      puts row.inspect
      my_transformation = ProductTransformation.create(production_title: row['production_title'], production_product_id: row['production_product_id'], staging_product_id: row['staging_product_id'], staging_variant_id: row['staging_variant_id'], staging_sku: row['staging_sku'])

    end


  end


  def setup_subscriptons_migration
    puts "Howdy"

    SubscriptionsMigrated.delete_all
      # Now reset index
    ActiveRecord::Base.connection.reset_pk_sequence!('subscriptions_migrated')


    my_active_subs = Subscription.where("status = ?", 'ACTIVE')
    my_active_subs.each do |mysub|
      puts mysub.inspect
      my_props = transform_properties(mysub.raw_line_item_properties)
      puts my_props.to_json
      #insert subscriptions_migrated here
      my_local_sub_migrate = SubscriptionsMigrated.create(subscription_id: mysub.subscription_id, address_id: mysub.subscription_id, customer_id: mysub.customer_id, created_at: mysub.created_at, updated_at: mysub.updated_at, next_charge_scheduled_at: mysub.next_charge_scheduled_at, cancelled_at: mysub.cancelled_at, product_title: mysub.product_title, price: mysub.price, quantity: mysub.quantity, status: mysub.status, shopify_product_id: mysub.shopify_product_id, shopify_variant_id: mysub.shopify_variant_id, sku: mysub.sku, order_interval_unit: mysub.order_interval_unit, order_interval_frequency: mysub.order_interval_frequency, charge_interval_frequency: mysub.charge_interval_frequency, order_day_of_month: mysub.order_day_of_month, order_day_of_week: mysub.order_day_of_week, raw_line_item_properties: mysub.raw_line_item_properties, synced_at: mysub.synced_at)



    end

  end

  def update_subscription_migration
    params = {"action" => "migrating subscriptions", "recharge_change_header" => @my_staging_change_header}
    puts "Sending to Resque job ... "
    Resque.enqueue(MigrateProductionSub, params)
  end

  class MigrateProductionSub
    extend ResqueHelper

    @queue = "migrate_production_subscription"
    def self.perform(params)
      # logger.info "UpdateSubscriptionProduct#perform params: #{params.inspect}"
      migrate_subscriptions(params)
    end
  end

  end
end