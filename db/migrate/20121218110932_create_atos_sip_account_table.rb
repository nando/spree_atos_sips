class CreateAtosSipAccountTable < ActiveRecord::Migration
  def self.up
    create_table :spree_atos_sips_accounts do |t|
      t.string :customer_id
      t.string :payment_means #=>"MASTERCARD",
      t.string :card_number #=>"4535.00",
    end
  end
 
  def self.down
    drop_table :spree_atos_sips_accounts
  end
end
