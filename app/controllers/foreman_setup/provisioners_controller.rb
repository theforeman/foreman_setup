require 'facter'

module ForemanSetup
  class ProvisionersController < ::ApplicationController
    include Foreman::Controller::ProvisioningTemplates
    include Foreman::Controller::Parameters::Medium
    include Foreman::Controller::Parameters::Subnet
    include Foreman::Renderer

    before_action :find_myself, :only => [:new, :create]
    before_action :find_resource, :except => [:index, :new, :create]

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
      @provisioner = Provisioner.new(provisioner_params)
      if @provisioner.save
        redirect_to step2_foreman_setup_provisioner_path(@provisioner)
      else
        @provisioner.host = @host
        @provisioner.smart_proxy = @proxy
        process_error :render => 'foreman_setup/provisioners/new', :object => @provisioner
      end
    end

    # Basic model created, now fill in nested subnet/domain info using selected interface
    def step2
      network = @provisioner.provision_interface_data
      @provisioner.subnet ||= Subnet.find_by_network(network[:network])
      @provisioner.subnet ||= Subnet.new(network.slice(:network, :mask).merge(
        :dns_primary => @provisioner.provision_interface_data[:ip]
      ))

      @provisioner.domain ||= @provisioner.host.domain
      @provisioner.domain ||= Domain.new(:name => 'example.com')
    end

    def step2_update
      @provisioner.hostgroup ||= Hostgroup.where(:name => _("Provision from %s") % @provisioner.fqdn).first_or_create
      @provisioner.subnet ||= Subnet.find_by_id(params['foreman_setup_provisioner']['subnet_attributes']['id'])
      domain_name = provisioner_params['domain_name']
      @provisioner.domain = Domain.find_by_name(domain_name)
      @provisioner.domain ||= Domain.new(:name => domain_name)

      if @provisioner.update_attributes(provisioner_params)
        @provisioner.subnet.domains << @provisioner.domain unless @provisioner.subnet.domains.include? @provisioner.domain
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
      url.value ||= Facter.value(:fqdn)
      url.save!

      # Build default PXE menu
      status, msg = ProvisioningTemplate.build_pxe_default(self)
      warning msg unless status == 200

      @provisioner.hostgroup.medium ||= @provisioner.host.os.media.first
      @medium = Medium.new(provisioner_params.try(:[], 'medium_attributes'))
    end

    def step4_update
      medium_id = params['foreman_setup_provisioner']['hostgroup_attributes'].try(:[], 'medium_id')
      if medium_id.to_i > 0
        @medium = Medium.find(medium_id) || raise('unable to find medium')
      else
        @provisioner.hostgroup.medium_id = nil
        @medium = Medium.new(provisioner_params['create_medium'].slice(:name, :path))
      end

      # Associate medium with the host OS
      @medium.os_family ||= @provisioner.host.os.type
      @medium.operatingsystems << @provisioner.host.os unless @medium.operatingsystems.include? @provisioner.host.os
      unless @medium.save
        process_error :render => 'foreman_setup/provisioners/step4', :object => @provisioner, :redirect => step4_foreman_setup_provisioner_path
        return
      end

      # Associate templates with OS and vice-versa
      if @provisioner.host.os.family && @provisioner.host.os.family.casecmp('Redhat').zero?
        tmpl_name = 'Kickstart'
        provision_tmpl_name = @provisioner.host.os.name.casecmp('Redhat').zero? ? 'Kickstart RHEL' : tmpl_name
        ipxe_tmpl_name = 'Kickstart'
        finish_tmpl_name = 'Kickstart default finish'
        ptable_name = 'Kickstart default'
      elsif @provisioner.host.os.family == 'Debian'
        tmpl_name = provision_tmpl_name = 'Preseed'
        finish_tmpl_name = 'Preseed default finish'
        ptable_name = 'Preseed default'
      end

      {'provision' => provision_tmpl_name, 'PXELinux' => tmpl_name, 'iPXE' => ipxe_tmpl_name, 'finish' => finish_tmpl_name}.each do |kind_name, tmpl_name|
        next if tmpl_name.blank?
        kind = TemplateKind.find_by_name(kind_name)
        tmpls = ProvisioningTemplate.where('name LIKE ?', "#{tmpl_name}%").where(:template_kind_id => kind.id)
        tmpls.any? || raise("cannot find template for #{@provisioner.host.os}")

        # prefer foreman_bootdisk templates
        tmpl = tmpls.where("name LIKE '%sboot disk%s'").first || tmpls.first

        tmpl.operatingsystems << @provisioner.host.os unless tmpl.operatingsystems.include? @provisioner.host.os
        tmpl.save!

        unless @provisioner.host.os.os_default_templates.where(:template_kind_id => kind.id).any?
          @provisioner.host.os.os_default_templates.build(:template_kind_id => kind.id, :provisioning_template_id => tmpl.id)
        end
      end

      @provisioner.host.os.architectures << @provisioner.host.architecture unless @provisioner.host.os.architectures.include? @provisioner.host.architecture
      @provisioner.host.os.save!

      ptable = Ptable.where('name LIKE ?', "#{ptable_name}%").first || raise("cannot find ptable for #{@provisioner.host.os}")
      ptable.operatingsystems << @provisioner.host.os unless ptable.operatingsystems.include? @provisioner.host.os
      ptable.save!

      @provisioner.hostgroup.medium_id = @medium.id
      @provisioner.hostgroup.ptable_id ||= ptable.id
      @provisioner.hostgroup.save!

      process_success :success_msg => _("Successfully associated OS %s.") % @provisioner.host.os.to_s, :success_redirect => step5_foreman_setup_provisioner_path
    end

    private

    # foreman_setup manages only itself at the moment, so ensure we always have a reference to
    # the Host and SmartProxy on this server
    def find_myself
      fqdn = Facter.value(:fqdn)
      @host = Host.find_by_name(fqdn)
      @proxy = SmartProxy.all.find { |p| URI.parse(p.url).host == fqdn }
    end

    def find_resource
      @provisioner = Provisioner.authorized(:edit_provisioning).find(params[:id]) or raise('unknown id')
    end

    def provisioner_params
      @provisioner_params ||=
        begin
          medium_attrs = self.class.medium_params_filter.filter(parameter_filter_context)
          subnet_attrs = self.class.subnet_params_filter.filter(parameter_filter_context)

          params.permit(:'foreman_setup_provisioner' => [
            :domain_name,
            :host,
            :host_id,
            :provision_interface,
            :smart_proxy,
            :smart_proxy_id,
            :subnet,
            :create_medium => medium_attrs,
            :hostgroup_attributes => [:id],
            :medium_attributes => medium_attrs,
            :subnet_attributes => subnet_attrs,
          ])['foreman_setup_provisioner']
        end
    end
  end
end
