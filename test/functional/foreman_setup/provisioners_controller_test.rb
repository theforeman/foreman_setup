require 'test_plugin_helper'

class ForemanSetup::ProvisionersControllerTest < ActionController::TestCase
  test '#index without provisioner' do
    get :index, {}, set_session_user
    assert_redirected_to new_foreman_setup_provisioner_path
  end

  test '#index with provisioner' do
    FactoryGirl.create :setup_provisioner
    get :index, {}, set_session_user
    assert_response :success
    assert_template 'foreman_setup/provisioners/index'
  end

  context 'pre-creation' do
    setup do
      @host = FactoryGirl.create(:host, :domain => FactoryGirl.create(:domain))
      Facter.expects(:value).with(:fqdn).returns(@host.name).at_least_once
      @proxy = FactoryGirl.create(:smart_proxy, :url => "https://#{@host.name}:8443")
    end

    test '#new' do
      get :new, {}, set_session_user
      assert_response :success
      assert_equal @host, assigns(:host)
      assert_equal @proxy, assigns(:proxy)
      assert_template 'foreman_setup/provisioners/_step1'
    end

    test '#create success' do
      post :create, {'foreman_setup_provisioner' => {:host_id => @host.id, :smart_proxy_id => @proxy.id, :provision_interface => 'eth0'}}, set_session_user

      prov = ForemanSetup::Provisioner.find_by_host_id(@host.id)
      assert prov
      assert_equal @host, prov.host
      assert_equal @proxy, prov.smart_proxy
      assert_equal 'eth0', prov.provision_interface

      assert_redirected_to step2_foreman_setup_provisioner_path(prov)
    end

    test '#create failure' do
      post :create, {}, set_session_user
      assert_equal @host, assigns(:host)
      assert_equal @proxy, assigns(:proxy)
      assert_template 'foreman_setup/provisioners/_step1'
    end
  end

  test '#step2 with new subnet' do
    prov = FactoryGirl.create(:setup_provisioner, :step1)
    get :step2, {:id => prov.id}, set_session_user
    assert_response :success
    assert_template 'foreman_setup/provisioners/_step2'

    assert assigns(:provisioner).subnet.new_record?
    assert_equal '192.168.1.0', assigns(:provisioner).subnet.network
    assert_equal '255.255.255.0', assigns(:provisioner).subnet.mask
    assert_equal '192.168.1.20', assigns(:provisioner).subnet.dns_primary

    assert_equal prov.host.domain, assigns(:provisioner).domain
  end

  test '#step2_update' do
    prov = FactoryGirl.create(:setup_provisioner, :step1)
    Facter.expects(:value).with(:fqdn).returns(prov.host.name).at_least_once

    put :step2_update, {:id => prov.id, 'foreman_setup_provisioner' => {:subnet_attributes => {'name' => 'test', :network => '192.168.1.0', :mask => '255.255.255.0'}, :domain_name => prov.host.domain.name}}, set_session_user
    assert_redirected_to step3_foreman_setup_provisioner_path(prov)

    prov.reload

    # Check new hg was created
    assert Hostgroup.find_by_name("Provision from #{prov.host.name}")
    assert prov.hostgroup

    # Check nested subnet was created and saved
    subnet = Subnet.find_by_network('192.168.1.0')
    assert subnet
    assert_equal 'test', subnet.name
    assert prov.subnet

    # Check domain was saved
    assert_equal prov.host.domain, prov.domain

    # Check domain/subnet association
    assert_includes prov.domain.subnets, subnet
  end

  test '#step3' do
    prov = FactoryGirl.create(:setup_provisioner, :step2)
    get :step3, {:id => prov.id}, set_session_user
    assert_response :success
    assert_template 'foreman_setup/provisioners/_step3'
  end

  test '#step4' do
    prov = FactoryGirl.create(:setup_provisioner, :step2)

    SmartProxy.any_instance.expects(:refresh)
    prov.smart_proxy.features = Feature.where(:name => ['DNS', 'DHCP', 'TFTP'])
    prov.smart_proxy.save!

    ProvisioningTemplate.expects(:build_pxe_default).returns(200, 'Sucess')

    get :step4, {:id => prov.id}, set_session_user
    assert_response :success
    assert_template 'foreman_setup/provisioners/_step4'
    assert assigns(:medium)

    prov.reload

    # Check proxy feature-based assignments worked
    assert_equal prov.smart_proxy.id, prov.subnet.dns_id
    # assert_equal prov.smart_proxy.id, prov.domain.dns_id # BUG, not saved
    assert_equal prov.smart_proxy.id, prov.subnet.dhcp_id
    assert_equal prov.smart_proxy.id, prov.subnet.tftp_id
  end

  test '#step4_update' do
    prov = FactoryGirl.create(:setup_provisioner, :step2)

    attrs = {
      :hostgroup_attributes => {},
      :create_medium => {:name => 'test', :path => 'http://mirror.example.com'},
    }
    put :step4_update, {:id => prov.id, 'foreman_setup_provisioner' => attrs}, set_session_user
    assert_redirected_to step5_foreman_setup_provisioner_path(prov)

    prov.reload

    assert prov.hostgroup.medium
    assert_equal 'test', prov.hostgroup.medium.name
    assert_equal 'http://mirror.example.com', prov.hostgroup.medium.path

    assert prov.hostgroup.ptable

    # TODO: assert that the OS and templates are all correctly associated
  end

  test '#step5' do
    prov = FactoryGirl.create(:setup_provisioner, :step2)
    get :step5, {:id => prov.id}, set_session_user
    assert_response :success
    assert_template 'foreman_setup/provisioners/_step5'
  end
end
