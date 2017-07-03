Puppet::Type.type(:quagga_bgp_peer_address_family).provide :quagga do
  @doc = 'Manages the address family of bgp peers using quagga.'

  confine osfamily: :redhat

  commands vtysh: 'vtysh'

  @resource_map = {
    peer_group: {
      default: :false,
      regexp: /\A\sneighbor\s(\S+)\speer-group(?:\s(\w+))?\Z/,
      template: 'neighbor <%= name %> peer-group<% unless value.nil? %> <%= value %><% end %>',
      type: :string,
    },
    activate: {
      regexp: /\A\s(?:(no)\s)?neighbor\s(\S+)\sactivate\Z/,
      template: 'neighbor <%= name %> activate',
      type: :boolean,
    },
    allow_as_in: {
      default: :absent,
      regexp: /\A\sneighbor\s(\S+)\sallowas-in\s(\d+)\Z/,
      template: 'neighbor <%= name %> allowas-in<% unless value.nil? %> <%= value %><% end %>',
      type: :fixnum,
    },
    default_originate: {
      default: :false,
      regexp: /\A\sneighbor\s(\S+)\sdefault-originate\Z/,
      template: 'neighbor <%= name %> default-originate',
      type: :boolean,
    },
    next_hop_self: {
      default: :false,
      regexp: /\A\sneighbor\s(\S+)\snext-hop-self\Z/,
      template: 'neighbor <%= name %> next-hop-self',
      type: :boolean,
    },
    prefix_list_in: {
      default: :absent,
      regexp: /\A\sneighbor\s(\S+)\sprefix-list\s(\S+)\sin\Z/,
      template: 'neighbor <%= name %> prefix-list <%= value %> in',
      type: :string,
    },
    prefix_list_out: {
      default: :absent,
      regexp: /\A\sneighbor\s(\S+)\sprefix-list\s(\S+)\sout\Z/,
      template: 'neighbor <%= name %> prefix-list <%= value %> out',
      type: :string,
    },
    route_map_export: {
      default: :absent,
      regexp: /\A\sneighbor\s(\S+)\sroute-map\s(\S+)\sexport\Z/,
      template: 'neighbor <%= name %> route-map <%= value %> export',
      type: :string,
    },
    route_map_import: {
      default: :absent,
      regexp: /\A\sneighbor\s(\S+)\sroute-map\s(\S+)\simport\Z/,
      template: 'neighbor <%= name %> route-map <%= value %> import',
      type: :string,
    },
    route_map_in: {
      default: :absent,
      regexp: /\A\sneighbor\s(\S+)\sroute-map\s(\S+)\sin\Z/,
      template: 'neighbor <%= name %> route-map <%= value %> in',
      type: :string,
    },
    route_map_out: {
      default: :absent,
      regexp: /\A\sneighbor\s(\S+)\sroute-map\s(\S+)\sout\Z/,
      template: 'neighbor <%= name %> route-map <%= value %> out',
      type: :string,
    },
    route_reflector_client: {
      default: :false,
      regexp: /\A\sneighbor\s(\S+)\sroute-reflector-client\Z/,
      template: 'neighbor <%= name %> route-reflector-client',
      type: :boolean,
    },
    route_server_client: {
      default: :false,
      regexp: /\A\sneighbor\s(\S+)\sroute-server-client\Z/,
      template: 'neighbor <%= name %> route-server-client',
      type: :boolean,
    },
  }

  def self.instances
    # TODO
    providers = []
    hash = {}
    found_router = false
    address_family = :ipv4_unicast
    as_number = ''
    previous_peer_name = ''
    default_ipv4_unicast = :true
    peer_group_default_ipv4_unicast = {}

    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|
      # Skip comments
      next if line =~ /\A!/

      # Found the router bgp
      if line =~ /\Arouter\sbgp\s(\d+)\Z/
        as_number = $1
        found_router = true

      # Found defult_ipv4_unicast
      elsif found_router and line =~ /\A\sno\sbgp\sdefault\sipv4-unicast\Z/
        default_ipv4_unicast = :false

      # Found the address family
      elsif found_router and line =~ /\A\saddress-family\s(ipv4|ipv6)(?:\s(multicast))?\Z/
        proto = $1
        type = $2
        address_family = type.nil? ? "#{proto}_unicast".to_sym : "#{proto}_#{type}".to_sym

      # Exit
      elsif found_router and line =~ /\A\w/
        break

      elsif found_router
        @resource_map.each do |property, options|
          if options[:regexp] =~ line
            if property == :activate
              peer_name = $2
              value = $1
            else
              peer_name = $1
              value = $2
            end

            unless peer_name == previous_peer_name
              unless hash.empty?
                # TODO activate
                if hash[:peer_group] == :true
                  peer_group_default_ipv4_unicast[previous_peer_name] = hash[:activate]
                elsif hash[:peer_group] == :false
                  hash[:activate] = address_family == :ipv4_unicast ? default_ipv4_unicast : :false
                else
                  hash[:activate] = peer_group_default_ipv4_unicast[hash[:peer_group]]
                end

                debug 'Instantiated bgp peer address family %{name}.' % { name: hash[:name] }
                providers << new(hash)
              end

              hash = {
                ensure: :present,
                name: "#{peer_name} #{address_family}",
                provider: self.name,
              }

              # Add default values
              @resource_map.each do |property, options|
                if options.has_key?(:default)
                  if [:array, :hash].include?(options[:type])
                    hash[property] = options[:default].clone
                  else
                    hash[property] = options[:default]
                  end
                end
              end

              previous_peer_name = peer_name
            end

            if value.nil?
              hash[property] = :true
            elsif property == :activete
              hash[property] = :false
            else
              case options[:type]
              when :array
                hash[property] << value
              when :fixnum
                hash[property] = Integer(value)
              when :symbol
                hash[property] = value.gsub(/-/, '_').to_sym
              else
                hash[property] = value
              end
            end
          end
        end
      end
    end

    unless hash.empty?
      debug 'Instantiated bgp peer address family %{name}.' % { name: hash[:name] }
      providers << new(hash)
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
