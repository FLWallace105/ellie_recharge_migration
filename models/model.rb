#model.rb
class Address < ActiveRecord::Base
    self.table_name = "addresses"
  end

class Subscription < ActiveRecord::Base
  self.table_name = "subscriptions"
end

class SubscriptionsMigrated < ActiveRecord::Base
  self.table_name = "subscriptions_migrated"
end

class ProductTransformation < ActiveRecord::Base
  self.table_name = "product_transformations"
end

class ProductionProductInfo < ActiveRecord::Base
  self.table_name = "production_product_info"
end

class StagingProductInfo < ActiveRecord::Base
  self.table_name = "staging_product_info"
end

class Customer < ActiveRecord::Base
  self.table_name = "customers"
end