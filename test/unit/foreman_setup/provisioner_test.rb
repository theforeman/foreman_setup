require 'test_helper'

class ForemanSetupProvisionerTest < ActiveSupport::TestCase
  test '#interfaces returns hash' do
    prov = FactoryGirl.create(:setup_provisioner, :step1)
    assert_equal({'eth0' => {:ip => '192.168.1.20', :mask => '255.255.255.0', :network => '192.168.1.0', :cidr => '192.168.1.0/24'}}, prov.interfaces)
  end

  test '#provision_interface_data returns hash' do
    prov = FactoryGirl.create(:setup_provisioner, :step1)
    assert_equal({:ip => '192.168.1.20', :mask => '255.255.255.0', :network => '192.168.1.0', :cidr => '192.168.1.0/24'}, prov.provision_interface_data)
  end
end
