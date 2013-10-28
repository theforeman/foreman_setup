Deface::Override.new(:virtual_path => 'subnets/_fields',
                     :name => 'remove_subnet_proxies',
                     :surround_contents => 'code[erb-loud]:contains("SmartProxy.")',
                     :text => <<EOS
unless controller.controller_name == 'provisioners'
  <%= render_original %>
end
EOS
)
