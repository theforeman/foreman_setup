require 'facter'

module ForemanSetup
  class ProvisionersController < ::ApplicationController
    before_filter :find_myself, :only => [:new, :create]

    def index
    end

    def new
      @provisioner = Provisioner.new(:host => @host, :smart_proxy => @proxy)
    end

    def create
      @provisioner = Provisioner.new(params['foreman_setup_provisioner'])
      if @provisioner.save
        redirect_to step2_foreman_setup_provisioner_path(@provisioner)
      else
        @provisioner.host = @host
        @provisioner.smart_proxy = @proxy
        process_error :render => 'foreman_setup/provisioners/new', :object => @provisioner
      end
    end

    def step2
      @provisioner = Provisioner.find(params[:id]) or raise('unknown id')
      network = @provisioner.provision_interface_data
      @provisioner.subnet ||= Subnet.find_by_network(network[:network])
      @provisioner.subnet ||= Subnet.new(network.slice(:network, :mask).merge(
        :dhcp_id => @provisioner.smart_proxy.features.include?(Feature.find_by_name('DHCP')) ? @provisioner.smart_proxy.id : nil,
        :dns_id => @provisioner.smart_proxy.features.include?(Feature.find_by_name('DNS')) ? @provisioner.smart_proxy.id : nil,
        :tftp_id => @provisioner.smart_proxy.features.include?(Feature.find_by_name('TFTP')) ? @provisioner.smart_proxy.id : nil,
        :dns_primary => @provisioner.host.ip,
      ))
    end

    def step2_update
      @provisioner = Provisioner.find(params[:id]) or raise('unknown id')
      if @provisioner.update_attributes(params['foreman_setup_provisioner'])
        process_success :success_msg => _("Successfully updated subnet %s.") % @provisioner.subnet.name, :success_redirect => step3_foreman_setup_provisioner_path
      else
        process_error :render => 'foreman_setup/provisioners/step2', :object => @provisioner, :redirect => step2_foreman_setup_provisioner_path
      end
    end

    def step3
      @provisioner = Provisioner.find(params[:id]) or raise('unknown id')
    end

    private

    # foreman_setup manages only itself at the moment, so ensure we always have a reference to
    # the Host and SmartProxy on this server
    def find_myself
      fqdn = Facter.fqdn
      @host = Host.find_by_name(fqdn)
      @proxy = SmartProxy.all.find { |p| URI.parse(p.url).host == fqdn }
    end
  end
end
