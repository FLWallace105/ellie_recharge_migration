require 'redis'
require 'resque'
Resque.redis = Redis.new(url: ENV['REDIS_URL'])
require 'active_record'
#require 'sinatra'
require 'sinatra/activerecord/rake'
require 'resque/tasks'
require_relative 'migration'
require_relative 'prep_migration'
#require 'pry'

namespace :migration do
desc 'list current products'
task :get_addresses do |t|
    MigrateRecharge::Downloader.new.download_addresses
end

desc 'test create a checkout and subscription'
task :test_checkout do |t|
    MigrateRecharge::Downloader.new.test_checkout
end

#process_test_sub
desc 'test processing of test checkout and subscription'
task :test_processing do |t|
    MigrateRecharge::Downloader.new.process_test_sub
end

#set up subscriptions to be migrated
desc 'set up subscriptions to be migrated'
task :setup_subscription_migrated do |t|
    PrepMigration::Setup.new.setup_subscriptons_migration
end

#update_subscription_migration
desc 'send subscriptions to be migrated to resque job for migration'
task :send_subs_to_resque_migration do |t|
    PrepMigration::Setup.new.update_subscription_migration
end

#setup_transformations_table
desc 'load product_transformations table'
task :load_product_transformations do |t|
    PrepMigration::Setup.new.setup_transformations_table
end

#reload_product_transformations
desc 'reload product_transformations table from CSV file'
task :reload_product_transformations_table do |t|
    PrepMigration::Setup.new.reload_product_transformations
end

#setup_staging_product_info
desc 'set up staging product info for transformations table'
task :setup_staging_product_transformation do |t|
    PrepMigration::Setup.new.setup_staging_product_info

end


end