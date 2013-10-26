Deface::Override.new(:virtual_path => 'dashboard/index',
                     :name => 'add_dashboard_provisioners_link',
                     :surround_contents => 'code[erb-loud]:contains("title_actions")',
                     :original => '35e276b7102eaa4feb8a4a84f66fd4812216fd48',
                     :text => <<EOS
if ForemanSetup::Provisioner.any?
  <%= render_original %>
else
  title_actions link_to_if_authorized(_("Set up provisioning"), hash_for_new_foreman_setup_provisioner_path)
end
EOS
)
