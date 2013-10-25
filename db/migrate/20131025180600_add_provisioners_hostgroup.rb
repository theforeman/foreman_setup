class AddProvisionersHostgroup < ActiveRecord::Migration
  def change
    add_column :setup_provisioners, :hostgroup_id, :integer
  end
end
