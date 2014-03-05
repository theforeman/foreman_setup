class UpdateForemanSetupPermissions < ActiveRecord::Migration
  def self.up
    old_permission = ::Permission.where(:name => "edit_provisioning", :resource_type => nil).first
    new_permission = ::Permission.where(:name => "edit_provisioning", :resource_type => "ForemanSetup::Provisioner").first
    unless old_permission.nil?
      Filtering.where(:permission_id => old_permission.id).update_all(:permission_id => new_permission.id)
      old_permission.delete
    end
  end
end
