require 'ipaddr'

module ForemanSetup
  class Provisioner < ActiveRecord::Base
    include ::Authorization
    include ::Host::Hostmix

    before_save :populate_hostgroup

    belongs_to_host
    belongs_to :domain
    belongs_to :hostgroup, :autosave => true
    belongs_to :smart_proxy
    belongs_to :subnet
    has_one :architecture, :through => :host
    has_one :medium, :through => :hostgroup
    has_one :operatingsystem, :through => :host

    accepts_nested_attributes_for :hostgroup
    # TODO: further validation on the subnet's (usually optional) attributes
    accepts_nested_attributes_for :subnet

    validates :host_id, :presence => true, :uniqueness => true
    validates :smart_proxy_id, :presence => true

    def to_s
      host.try(:to_s)
    end

    def fqdn
      Facter.fqdn
    end

    def interfaces
      facts = host.facts_hash
      (facts['interfaces'] || '').split(',').reject { |i| i == 'lo' }.inject({}) do |ifaces,i|
        ip = facts["ipaddress_#{i}"]
        network = facts["network_#{i}"]
        netmask = facts["netmask_#{i}"]
        if ip && network && netmask
          cidr = "#{network}/#{IPAddr.new(netmask).to_i.to_s(2).count("1")}"
          ifaces[i] = {:ip => ip, :mask => netmask, :network => network, :cidr => cidr}
        end
        ifaces
      end
    end

    def provision_interface_data
      interfaces[provision_interface]
    end

    def rdns_zone
      netmask_octets = subnet.mask.split('.').reverse
      subnet.network.split('.').reverse.drop_while { |i| netmask_octets.shift == '0' }.join('.') + '.in-addr.arpa'
    end

    def dns_forwarders
      File.open('/etc/resolv.conf', 'r').each_line.map do |r|
        $1 if r =~ /^nameserver\s+(\S+)/
      end.compact
    end

    private

    # Ensures our nested hostgroup has as much data as possible
    def populate_hostgroup
      return unless hostgroup.present?
      hostgroup.architecture_id ||= domain.id
      hostgroup.domain_id ||= domain.id
      hostgroup.operatingsystem_id ||= operatingsystem.id
      hostgroup.puppet_ca_proxy_id = smart_proxy.id if smart_proxy.features.include? Feature.find_by_name('Puppet CA')
      hostgroup.puppet_proxy_id = smart_proxy.id if smart_proxy.features.include? Feature.find_by_name('Puppet')
      hostgroup.subnet_id ||= subnet.id
    end

  end
end
