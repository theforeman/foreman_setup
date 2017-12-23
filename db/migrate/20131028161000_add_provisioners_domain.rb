class AddProvisionersDomain < ActiveRecord::Migration[4.2]
  def change
    add_column :setup_provisioners, :domain_id, :integer
  end
end
