Puppet::Type.type(:quagga_bgp_peer_address_family).provide :quagga do
  @doc = 'Manages the address family of bgp peers using quagga.'

  commands vtysh: 'vtysh'

  @resource_map = {
    peer_group: {
      default: :false,
      regexp: %r{\A\sneighbor\s(\S+)\speer-group(?:\s(\w+))?\Z},
      template: 'neighbor <%= name %> peer-group<% unless value.nil? %> <%= value %><% end %>',
      type: :string,
    },
    activate: {
      regexp: %r{\A\s+(?:(no)\s)?neighbor\s(\S+)\sactivate\Z},
      template: 'neighbor <%= name %> activate',
      type: :boolean,
    },
    allow_as_in: {
      default: :absent,
      regexp: %r{\A\s+neighbor\s(\S+)\sallowas-in\s(\d+)\Z},
      template: 'neighbor <%= name %> allowas-in<% unless value.nil? %> <%= value %><% end %>',
      type: :fixnum,
    },
    default_originate: {
      default: :false,
      regexp: %r{\A\s+neighbor\s(\S+)\sdefault-originate\Z},
      template: 'neighbor <%= name %> default-originate',
      type: :boolean,
    },
    next_hop_self: {
      default: :false,
      regexp: %r{\A\s+neighbor\s(\S+)\snext-hop-self\Z},
      template: 'neighbor <%= name %> next-hop-self',
      type: :boolean,
    },
    prefix_list_in: {
      default: :absent,
      regexp: %r{\A\s+neighbor\s(\S+)\sprefix-list\s(\S+)\sin\Z},
      template: 'neighbor <%= name %> prefix-list <%= value %> in',
      type: :string,
    },
    prefix_list_out: {
      default: :absent,
      regexp: %r{\A\s+neighbor\s(\S+)\sprefix-list\s(\S+)\sout\Z},
      template: 'neighbor <%= name %> prefix-list <%= value %> out',
      type: :string,
    },
    route_map_export: {
      default: :absent,
      regexp: %r{\A\s+neighbor\s(\S+)\sroute-map\s(\S+)\sexport\Z},
      template: 'neighbor <%= name %> route-map <%= value %> export',
      type: :string,
    },
    route_map_import: {
      default: :absent,
      regexp: %r{\A\s+neighbor\s(\S+)\sroute-map\s(\S+)\simport\Z},
      template: 'neighbor <%= name %> route-map <%= value %> import',
      type: :string,
    },
    route_map_in: {
      default: :absent,
      regexp: %r{\A\s+neighbor\s(\S+)\sroute-map\s(\S+)\sin\Z},
      template: 'neighbor <%= name %> route-map <%= value %> in',
      type: :string,
    },
    route_map_out: {
      default: :absent,
      regexp: %r{\A\s+neighbor\s(\S+)\sroute-map\s(\S+)\sout\Z},
      template: 'neighbor <%= name %> route-map <%= value %> out',
      type: :string,
    },
    route_reflector_client: {
      default: :false,
      regexp: %r{\A\s+neighbor\s(\S+)\sroute-reflector-client\Z},
      template: 'neighbor <%= name %> route-reflector-client',
      type: :boolean,
    },
    route_server_client: {
      default: :false,
      regexp: %r{\A\s+neighbor\s(\S+)\sroute-server-client\Z},
      template: 'neighbor <%= name %> route-server-client',
      type: :boolean,
    },
  }

  def initialize(value)
    super(value)
    @property_flush = {}
  end

  def self.instances
    # TODO
    providers = []
    hash = {}
    found_router = false
    address_family = :ipv4_unicast
    as_number = ''
    previous_peer = ''
    found_activate = false

    config = vtysh('-c', 'show running-config')
    config.split(%r{\n}).map do |line|
      # Skipping comments
      next if %r{\A!}.match?(line) # rubocop:disable Performance/StartWith

      # Found the router bgp
      if line =~ %r{\Arouter\sbgp\s(\d+)\Z}
        as_number = Regexp.last_match(1)
        found_router = true

      # Found the address family
      elsif found_router && line =~ (%r{\A\saddress-family\s(ipv4|ipv6)(?:\s(multicast))?\Z})
        proto = Regexp.last_match(1)
        type = Regexp.last_match(2)
        address_family = type.nil? ? "#{proto}_unicast" : "#{proto}_#{type}"

      # Exit
      elsif found_router && line =~ (%r{\A\w})
        break

      elsif found_router
        @resource_map.each do |property, options|
          next unless options[:regexp] =~ line
          if property == :activate
            peer = Regexp.last_match(2)
            value = Regexp.last_match(1)
          else
            peer = Regexp.last_match(1)
            value = Regexp.last_match(2)
          end

          unless peer == previous_peer
            unless hash.empty?
              debug 'Instantiated the bgp peer address family %{name}.' % { name: hash[:name] }
              providers << new(hash)
            end

            hash = {
              activate: :false,
              ensure: :present,
              name: "#{peer} #{address_family}",
              provider: name,
            }

            # Add default values
            @resource_map.each do |propertyx, optionsx|
              next unless optionsx.key?(:default)
              hash[propertyx] = if [:array, :hash].include?(optionsx[:type])
                                  optionsx[:default].clone
                                else
                                  optionsx[:default]
                                end
            end

            previous_peer = peer
            found_activate = false
          end

          found_activate = true if property == :activate

          if value.nil?
            hash[property] = :true
          elsif property == :activate
            hash[property] = :false
          else
            case options[:type]
            when :array
              hash[property] << value
            when :fixnum
              hash[property] = Integer(value)
            when :symbol
              hash[property] = value.tr('-', '_').to_sym
            else
              hash[property] = value
            end
          end
        end
      end
    end

    unless hash.empty?
      debug 'Instantiated the bgp peer address family %{name}.' % { name: hash[:name] }
      providers << new(hash)
    end

    providers
  end

  def self.prefetch(resources)
    providers = instances
    resources.each_key do |name|
      if (provider = providers.find { |providerx| providerx.name == name })
        resources[name].provider = provider
      end
    end
  end

  def clear
    return unless exists?

    peer_name, address_family = @property_hash[:name].split(%r{\s})

    debug 'Clearing the address family %{address_family_name} of the bgp peer %{peer_name}' % {
      address_family_name: address_family,
      peer_name: peer_name,
    }

    cmds = []

    cmds << if @property_hash[:peer_group] == :true
              'clear bgp peer-group %{name} soft' % { name: peer_name }
            else
              'clear bgp %{name} soft' % { name: peer_name }
            end

    vtysh(cmds.reduce([]) { |cmdsx, cmd| cmdsx << '-c' << cmd })
  end

  def create
    name, address_family = @resource[:name].split(%r{\s})

    debug 'Creating the address family %{address_family} of the bgp peer %{peer}' % {
      address_family: address_family,
      peer: name,
    }

    as_number = get_as_number
    resource_map = self.class.instance_variable_get('@resource_map')

    cmds = []
    cmds << 'configure terminal'
    cmds << 'router bgp %{as_number}' % { as_number: as_number }
    cmds << 'address-family %{address_family}' % {
      address_family: address_family_to_s(address_family)
    }

    resource_map.each do |property, options|
      if @resource[property] && (@resource[property] != options[:default])
        if @resource[property] == :true
          cmds << ERB.new(options[:template]).result(binding)

        elsif @resource[property] == :false
          cmds << 'no %{command}' % { command: ERB.new(options[:template]).result(binding) }

        elsif options[:type] == :array
          @resource[property].each do |value|
            cmds << ERB.new(options[:template]).result(binding)
          end

        else
          value = @resource[property]
          cmds << ERB.new(options[:template]).result(binding)
        end
      end
    end

    cmds << 'end'
    cmds << 'write memory'

    vtysh(cmds.reduce([]) { |commands, command| commands << '-c' << command })
  end

  def destroy
    name, address_family = @property_hash[:name].split(%r{\s})

    debug 'Destroying the address family %{address_family} of the bgp peer %{peer}' % {
      address_family: address_family,
      peer: name,
    }

    as_number = get_as_number
    resource_map = self.class.instance_variable_get('@resource_map')

    cmds = []
    cmds << 'configure terminal'
    cmds << 'router bgp %{as_number}' % { as_number: as_number }
    cmds << 'address-family %{address_family}' % {
      address_family: address_family_to_s(address_family)
    }

    resource_map.each do |property, options|
      unless @property_hash[property] == options[:default]
        if (@property_hash[property] == :true) || (property == :allow_as_in)
          cmds << 'no %{command}' % { command: ERB.new(resource_map[property][:template]).result(binding) }

        elsif options[:type] == :array
          @property_hash[property].each do |value|
            cmds << 'no %{command}' % { command: ERB.new(resource_map[property][:template]).result(binding) }
          end

        else
          value = @property_hash[property]
          cmds << 'no %{command}' % { command: ERB.new(resource_map[property][:template]).result(binding) }
        end
      end
    end

    cmds << 'end'
    cmds << 'write memory'

    vtysh(cmds.reduce([]) { |commands, command| commands << '-c' << command })

    @property_hash.clear
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def flush
    return if @property_flush.empty?

    name, address_family = @property_hash[:name].split(%r{\s})

    debug 'Flushing the address family %{address_family} of the bgp peer %{peer}' % {
      address_family: address_family,
      peer: name,
    }

    as_number = get_as_number
    resource_map = self.class.instance_variable_get('@resource_map')

    cmds = []
    cmds << 'configure terminal'
    cmds << 'router bgp %{as_number}' % { as_number: as_number }
    cmds << 'address-family %{address_family}' % {
      address_family: address_family_to_s(address_family)
    }

    @property_flush.each do |property, v|
      if (v == :absent) || (v == :false)
        if [:prefix_list_in, :prefix_list_out, :route_map_export,
            :route_map_import, :route_map_in, :route_map_out, :peer_group].include?(property)
          value = @property_hash[property] # TODO: Is this an unused assignment to value, or should it be v?
        end

        cmds << 'no %{command}' % { command: ERB.new(resource_map[property][:template]).result(binding) }

      elsif (v == :true) && [:symbol, :string].include?(resource_map[property][:type])
        cmds << 'no %{command}' % { command: ERB.new(resource_map[property][:template]).result(binding) }
        cmds << ERB.new(resource_map[property][:template]).result(binding)

      elsif v == :true
        cmds << ERB.new(resource_map[property][:template]).result(binding)

      elsif resource_map[property][:type] == :array
        (@property_hash[property] - v).each do |value| # rubocop:todo  Lint/ShadowingOuterLocalVariable
          cmds << 'no %{command}' % { command: ERB.new(resource_map[property][:template]).result(binding) }
        end

        (v - @property_hash[property]).each do |value| # rubocop:todo  Lint/ShadowingOuterLocalVariable
          cmds << ERB.new(resource_map[property][:template]).result(binding)
        end

      else
        value = v
        cmds << ERB.new(resource_map[property][:template]).result(binding)
      end
    end

    cmds << 'end'
    cmds << 'write memory'

    vtysh(cmds.reduce([]) { |commands, command| commands << '-c' << command })

    @property_hash = @resource.to_hash
    @property_flush.clear
  end

  @resource_map.each_key do |property|
    define_method property.to_s do
      @property_hash[property] || :absent
    end

    define_method "#{property}=" do |value|
      @property_flush[property] = value
    end
  end

  private

  def get_as_number
    if @as_number.nil?
      begin
        vtysh('-c', 'show running-config').split(%r{\n}).collect.each do |line|
          if line =~ %r{\Arouter\sbgp\s(\d+)\Z}
            @as_number = Integer(Regexp.last_match(1))
            break
          end
        end
      rescue
        # do nothing
      end
    end

    @as_number
  end

  def address_family_to_s(address_family)
    address_family == 'ipv6_unicast' ? 'ipv6' : address_family.tr('_', ' ')
  end
end
