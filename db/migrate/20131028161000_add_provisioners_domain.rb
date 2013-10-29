class AddProvisionersDomain < ActiveRecord::Migration
  def change
    add_column :setup_provisioners, :domain_id, :integer
  end
end
