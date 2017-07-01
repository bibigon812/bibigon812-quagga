Puppet::Type.type(:quagga_bgp_peer_address_family).provide :quagga do
  @doc = 'Manages the address family of bgp peers using quagga.'

  confine osfamily: :redhat

  commands vtysh: 'vtysh'

  @resource_map = {
      peer_group: {
          default: :false,
          template: 'neighbor <%= name %> peer-group <%= value %>',
          type: :string,
      },
      activate: {
          regexp: /\A\s(no\s)?neighbor\s\S+\sactivate\Z/,
          template: 'neighbor <%= name %> activate',
          type: :boolean,
      },
      allow_as_in: {
          regexp: /\A\sneighbor\s\S+\sallowas-in\s(\d+)\Z/,
          template: 'neighbor <%= name %> allowas-in<% unless value.nil? %> <%= value %><% end %>',
          type: :fixnum,
      },
      default_originate: {
          default: :false,
          regexp: /\A\sneighbor\s\S+\sdefault-originate\Z/,
          template: 'neighbor <%= name %> default-originate',
          type: :boolean,
      },
      next_hop_self: {
          default: :false,
          regexp: /\A\sneighbor\s\S+\snext-hop-self\Z/,
          template: 'neighbor <%= name %> next-hop-self',
          type: :boolean,
      },
      prefix_list_in: {
          regexp: /\A\sneighbor\s\S+\sprefix-list\s(\S+)\sin\Z/,
          template: 'neighbor <%= name %> prefix-list <%= value %> in',
          type: :string,
      },
      prefix_list_out: {
          regexp: /\A\sneighbor\s\S+\sprefix-list\s(\S+)\sout\Z/,
          template: 'neighbor <%= name %> prefix-list <%= value %> out',
          type: :string,
      },
      route_map_export: {
          regexp: /\A\sneighbor\s\S+\sroute-map\s(\S+)\sexport\Z/,
          template: 'neighbor <%= name %> route-map <%= value %> export',
          type: :string,
      },
      route_map_import: {
          value: '$1',
          regexp: /\A\sneighbor\s\S+\sroute-map\s(\S+)\simport\Z/,
          template: 'neighbor <%= name %> route-map <%= value %> import',
          type: :string,
      },
      route_map_in: {
          regexp: /\A\sneighbor\s\S+\sroute-map\s(\S+)\sin\Z/,
          template: 'neighbor <%= name %> route-map <%= value %> in',
          type: :string,
      },
      route_map_out: {
          regexp: /\A\sneighbor\s\S+\sroute-map\s(\S+)\sout\Z/,
          template: 'neighbor <%= name %> route-map <%= value %> out',
          type: :string,
      },
      route_reflector_client: {
          default: :false,
          regexp: /\A\sneighbor\s\S+\sroute-reflector-client\Z/,
          template: 'neighbor <%= name %> route-reflector-client',
          type: :boolean,
      },
      route_server_client: {
          default: :false,
          regexp: /\A\sneighbor\s\S+\sroute-server-client\Z/,
          template: 'neighbor <%= name %> route-server-client',
          type: :boolean,
      },
  }

  def self.instaneces
    # TODO
    providers = []
    hash = {}
    found_router = false
    address_family = 'ipv4 unicast'
    as = ''

    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|
      # Skip comments
      next if line =~ /\A!/

      # Found the router bgp
      if line =~ /\Arouter\sbgp\s(\d+)\Z/
        as = $1
        found_router = true

      # Found the address family
      elsif found_router and line =~ /\A\saddress-family\s(ipv4|ipv6)(?:\s(multicast))?\Z/
        proto = $1
        type = $2
        address_family = type.nil? ? proto : "#{proto} #{type}"

      # Exit
      elsif found_router and line =~ /\A\w/
        break

      end
    end

    providers
  end

  def self.prefetch(resources)
    providers = instances
    resources.keys.each do |name|
      if provider = providers.find{ |pkg| pkg.name == name }
        resources[name].provider = provider
      end
    end
  end

  # TODO
end

