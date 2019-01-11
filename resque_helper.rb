#resque_helper
require 'dotenv'
require 'active_support/core_ext'
require 'sinatra/activerecord'
require 'httparty'
require_relative 'models/model'


Dotenv.load

module ResqueHelper

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

    def transform_product_id(product_id, variant_id)


    end

    



    def migrate_subscriptions(params)
        puts "Starting background job ..."
        puts params.inspect

        my_subs = SubscriptionsMigrated.where(migrated_to_staging: false)
        my_subs.each do |sub|
            puts sub.inspect
            my_properties = transform_properties(sub.raw_line_item_properties)
            puts my_properties
        end

        puts "All done migrating subscriptions"

    end



end