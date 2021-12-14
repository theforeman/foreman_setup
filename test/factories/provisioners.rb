FactoryBot.define do
  factory :setup_provisioner, :class => ForemanSetup::Provisioner do
    host do
      association :host, :managed, :domain => FactoryBot.create(:domain)
    end
    smart_proxy { association :smart_proxy, :url => "https://#{host.name}:8443" }

    # After step1, interface selection
    trait :step1 do
      provision_interface { 'eth0' }
      after(:create) do |prov, evaluator|
        fact = FactoryBot.create(:fact_name, :name => "ipaddress_#{prov.provision_interface}")
        FactoryBot.create(:fact_value, :fact_name => fact, :host => prov.host, :value => '192.168.1.20')

        fact = FactoryBot.create(:fact_name, :name => "network_#{prov.provision_interface}")
        FactoryBot.create(:fact_value, :fact_name => fact, :host => prov.host, :value => '192.168.1.0')

        fact = FactoryBot.create(:fact_name, :name => "netmask_#{prov.provision_interface}")
        FactoryBot.create(:fact_value, :fact_name => fact, :host => prov.host, :value => '255.255.255.0')

        fact = FactoryBot.create(:fact_name, :name => 'interfaces')
        FactoryBot.create(:fact_value, :fact_name => fact, :host => prov.host, :value => 'lo,eth0,eth1')
      end
    end

    # After step2_update, update with nested subnet data
    trait :step2 do
      step1
      hostgroup
      domain
      association :subnet, :factory => :subnet_ipv4
      after(:create) do |prov, evaluator|
        prov.subnet.domains << prov.domain
      end
    end
  end
end
