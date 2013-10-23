class AddProvisioners < ActiveRecord::Migration
  def change
    create_table :setup_provisioners do |t|
      t.integer :host_id
      t.integer :smart_proxy_id
      t.string :provision_interface
      t.integer :subnet_id
      t.string :timestamps
    end
  end
end
