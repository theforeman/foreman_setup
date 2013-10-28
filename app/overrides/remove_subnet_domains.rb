Deface::Override.new(:virtual_path => 'subnets/_fields',
                     :name => 'remove_subnet_domains',
                     :surround_contents => 'code[erb-loud]:contains("multiple_checkboxes f, :domain")',
                     :text => <<EOS
unless controller.controller_name == 'provisioners'
  <%= render_original %>
end
EOS
)
