Deface::Override.new(:virtual_path => 'subnets/_fields',
                     :name => 'remove_subnet_proxies',
                     :remove => 'code[erb-loud]:contains("SmartProxy.")')
