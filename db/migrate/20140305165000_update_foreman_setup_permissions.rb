class UpdateForemanSetupPermissions < ActiveRecord::Migration
  def self.up
    old_permission = ::Permission.where(:name => "edit_provisioning", :resource_type => nil).first
    new_permssion = ::Permission.where(:name => "edit_provisioning", :resource_type => "ForemanSetup::Provisioner").first
    unless old_permission.nil?
      Filtering.where(:permission => old_permission).update_all(:permssion => new_permission)
      old_permssion.delete
    end
  end
end
