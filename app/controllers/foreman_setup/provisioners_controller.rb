require 'facter'

module ForemanSetup
  class ProvisionersController < ::ApplicationController
    include Foreman::Renderer

    before_filter :find_myself, :only => [:new, :create]
    before_filter :find_resource, :except => [:index, :new, :create]

    def index
      @provisioners = Provisioner.all.paginate :page => params[:page]
      redirect_to new_foreman_setup_provisioner_path unless @provisioners.any?
    end

    def destroy
      @provisioner = Provisioner.find(params[:id])
      if @provisioner.destroy
        process_success :success_redirect => foreman_setup_provisioners_path
      else
        process_error
      end
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

    # Basic model created, now fill in nested subnet info using selected interface
    def step2
      network = @provisioner.provision_interface_data
      @provisioner.subnet ||= Subnet.find_by_network(network[:network])
      @provisioner.subnet ||= Subnet.new(network.slice(:network, :mask).merge(
        :dns_primary => @provisioner.provision_interface_data[:ip],
      ))
    end

    def step2_update
      @provisioner.hostgroup ||= Hostgroup.new(:name => _("Provision from %s") % @provisioner.fqdn)
      @provisioner.subnet ||= Subnet.find_by_id(params['foreman_setup_provisioner']['subnet_attributes']['id'])
      @provisioner.subnet.domains << @provisioner.domain unless @provisioner.subnet.domains.include? @provisioner.domain
      if @provisioner.update_attributes(params['foreman_setup_provisioner'])
        process_success :success_msg => _("Successfully updated subnet %s.") % @provisioner.subnet.name, :success_redirect => step3_foreman_setup_provisioner_path
      else
        process_error :render => 'foreman_setup/provisioners/step2', :object => @provisioner, :redirect => step2_foreman_setup_provisioner_path
      end
    end

    # foreman-installer info screen
    def step3
    end

    # Installer completed, start associating data, begin install media setup
    def step4
      # Refresh proxy features (1.4 versus 1.3 techniques)
      proxy = @provisioner.smart_proxy
      proxy.respond_to?(:refresh) ? proxy.refresh : proxy.ping
      proxy.save!

      # Associate as much as possible
      if proxy.features.include? Feature.find_by_name('DNS')
        @provisioner.domain.dns_id ||= proxy.id
        @provisioner.subnet.dns_id ||= proxy.id
      end
      if proxy.features.include? Feature.find_by_name('DHCP')
        @provisioner.subnet.dhcp_id ||= proxy.id
      end
      if proxy.features.include? Feature.find_by_name('TFTP')
        @provisioner.subnet.tftp_id ||= proxy.id
      end
      @provisioner.save!

      # Helpful fix to work around #3210
      url = Setting.find_by_name('foreman_url')
      url.value ||= Facter.fqdn
      url.save!

      # Build default PXE menu
      status, msg = ConfigTemplate.build_pxe_default(self)
      warning msg unless status == 200

      @provisioner.medium = @provisioner.host.os.media.first
      @medium = Medium.new(params['foreman_setup_provisioner'].try(:[], 'medium_attributes'))

      @activation_key = CommonParameter.find_by_name('activation_key') || CommonParameter.new(:name => 'activation_key')
      @satellite_type = CommonParameter.find_by_name('satellite_type') || CommonParameter.new(:name => 'satellite_type')
    end

    def step4_update
      if params['foreman_setup_provisioner']['medium'].to_i > 0
        @medium = Medium.find(params['foreman_setup_provisioner']['medium']) || raise('unable to find medium')
      else
        @medium = Medium.new(params['foreman_setup_provisioner']['create_medium'].slice(:name, :path))
      end

      @activation_key = CommonParameter.find_by_name('activation_key')
      @activation_key ||= CommonParameter.new(params['foreman_setup_provisioner']['activation_key'].merge(:name => 'activation_key'))

      @satellite_type = CommonParameter.find_by_name('satellite_type')
      @satellite_type ||= CommonParameter.new(params['foreman_setup_provisioner']['satellite_type'].merge(:name => 'satellite_type'))

      # Associate medium with the host OS
      @medium.os_family ||= @provisioner.host.os.type
      @medium.operatingsystems << @provisioner.host.os unless @medium.operatingsystems.include? @provisioner.host.os
      unless @medium.save
        process_error :render => 'foreman_setup/provisioners/step4', :object => @provisioner, :redirect => step4_foreman_setup_provisioner_path
        return
      end

      # Only store parameters unless they're new and blank
      unless @activation_key.new_record? && @activation_key.value.blank?
        @activation_key.save!
      end
      unless @satellite_type.new_record? && @satellite_type.value.blank?
        @satellite_type.save!
      end

      # Associate templates with OS and vice-versa
      if @provisioner.host.os.family == 'Redhat'
        tmpl_name = 'Kickstart'
        provision_tmpl_name = @provisioner.host.os.name == 'Redhat' ? 'RHEL Kickstart' : tmpl_name
        ptable_name = 'RedHat default'
      elsif @provisioner.host.os.family == 'Debian'
        tmpl_name = provision_tmpl_name = 'Preseed'
        ptable_name = 'Ubuntu default'
      end

      {'provision' => provision_tmpl_name, 'PXELinux' => tmpl_name}.each do |kind_name, tmpl_name|
        kind = TemplateKind.find_by_name(kind_name)
        tmpl = ConfigTemplate.where('name LIKE ?', "#{tmpl_name}%").where(:template_kind_id => kind.id).first || raise("cannot find template for #{@provisioner.host.os}")
        tmpl.operatingsystems << @provisioner.host.os unless tmpl.operatingsystems.include? @provisioner.host.os
        tmpl.save!

        unless @provisioner.host.os.os_default_templates.where(:template_kind_id => kind.id).any?
          @provisioner.host.os.os_default_templates.build(:template_kind_id => kind.id, :config_template_id => tmpl.id)
        end
      end

      @provisioner.host.os.architectures << @provisioner.host.architecture unless @provisioner.host.os.architectures.include? @provisioner.host.architecture
      @provisioner.host.os.save!

      ptable = Ptable.where('name LIKE ?', "#{ptable_name}%").first || raise("cannot find ptable for #{@provisioner.host.os}")
      ptable.operatingsystems << @provisioner.host.os unless ptable.operatingsystems.include? @provisioner.host.os
      ptable.save!

      @provisioner.hostgroup.medium_id ||= @medium.id
      @provisioner.hostgroup.ptable_id ||= ptable.id
      @provisioner.hostgroup.save!

      process_success :success_msg => _("Successfully associated OS %s.") % @provisioner.host.os.to_s, :success_redirect => step5_foreman_setup_provisioner_path
    end

    private

    # foreman_setup manages only itself at the moment, so ensure we always have a reference to
    # the Host and SmartProxy on this server
    def find_myself
      fqdn = Facter.fqdn
      @host = Host.find_by_name(fqdn)
      @proxy = SmartProxy.all.find { |p| URI.parse(p.url).host == fqdn }
    end

    def find_resource
      @provisioner = Provisioner.find(params[:id]) or raise('unknown id')
    end

  end
end
