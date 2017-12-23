class AddProvisionersHostgroup < ActiveRecord::Migration[4.2]
  def change
    add_column :setup_provisioners, :hostgroup_id, :integer
  end
end
