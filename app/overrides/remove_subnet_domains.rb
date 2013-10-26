Deface::Override.new(:virtual_path => 'subnets/_fields',
                     :name => 'remove_subnet_domains',
                     :remove => 'code[erb-loud]:contains("multiple_checkboxes f, :domain")')
