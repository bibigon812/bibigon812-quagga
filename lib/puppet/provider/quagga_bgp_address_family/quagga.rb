Puppet::Type.type(:quagga_bgp_address_family).provide :quagga do
  @doc = 'Manages bgp address family using quagga.'

  commands vtysh: 'vtysh'

  @resource_map = {
    aggregate_address: {
      default: [],
      regexp: %r{\A\s+aggregate-address\s(.+)\Z},
      template: 'aggregate-address<% unless value.nil? %> <%= value %><% end %>',
      type: :array,
    },
    maximum_ebgp_paths: {
      default: 1,
      regexp: %r{\A\s+maximum-paths\s(\d+)\Z},
      template: 'maximum-paths<% unless value.nil? %> <%= value %><% end %>',
      type: :fixnum,
    },
    maximum_ibgp_paths: {
      default: 1,
      regexp: %r{\A\s+maximum-paths\sibgp\s(\d+)\Z},
      template: 'maximum-paths ibgp<% unless value.nil? %> <%= value %><% end %>',
      type: :fixnum,
    },
    networks: {
      default: [],
      regexp: %r{\A\s+network\s(.+)\Z},
      template: 'network<% unless value.nil? %> <%= value %><% end %>',
      type: :array,
    },
    redistribute: {
      default: [],
      regexp: %r{\A\s+redistribute\s(.+)\Z},
      template: 'redistribute<% unless value.nil? %> <%= value %><% end %>',
      type: :array,
    },
  }

  def self.instances
    providers = []
    hash = {}
    found_router = false
    proto = 'ipv4'
    type = 'unicast'
    as = ''

    config = vtysh('-c', 'show running-config')
    config.split(%r{\n}).map do |line|
      # Skip comments
      next if %r{\A!}.match?(line) # rubocop:disable Performance/StartWith

      # Found the router bgp
      if line =~ %r{\Arouter\sbgp\s(\d+)\Z}
        as = Regexp.last_match(1)
        found_router = true

        hash = {
          ensure: :present,
            name: "#{proto}_#{type}",
            provider: name,
        }

        # Add default values
        @resource_map.each do |property, options|
          next unless options.key?(:default)
          hash[property] = if [:array, :hash].include?(options[:type])
                             options[:default].clone
                           else
                             options[:default]
                           end
        end

      # Found the address family
      elsif found_router && line =~ (%r{\A\saddress-family\s(ipv4|ipv6)(?:\s(multicast))?\Z})
        proto = Regexp.last_match(1)
        type = Regexp.last_match(2).nil? ? 'unicast' : Regexp.last_match(2)

        debug 'Instantiated the bgp address family %{address_family}.' % {
          address_family: hash[:name]
        }

        providers << new(hash)

        # Create new address family
        hash = {
          ensure: :present,
            name: "#{proto}_#{type}",
            provider: name,
        }

        # Add default values
        @resource_map.each do |property, options|
          next unless options.key?(:default)
          hash[property] = if [:array, :hash].include?(options[:type])
                             options[:default].clone
                           else
                             options[:default]
                           end
        end

      elsif found_router && line =~ (%r{\A\w})
        # Exit from the router bgp
        break

      # Inside the router bgp
      elsif found_router
        @resource_map.each do |property, options|
          next unless line =~ options[:regexp]
          value = Regexp.last_match(1)

          if value.nil?
            hash[property] = :true

          else
            case options[:type]
            when :array
              hash[property] << value
            when :fixnum
              hash[property] = value.to_i
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
      debug 'Instantiated the bgp address family %{address_family}.' % {
        address_family: hash[:name]
      }

      providers << new(hash)
    end

    providers
  end

  def self.prefetch(resources)
    debug '[prefetch]'
    providers = instances
    resources.each_key do |name|
      if (provider = providers.find { |providerx| providerx.name == name })
        resources[name].provider = provider
      end
    end
  end

  def create
    proto, type = @resource[:name].split(%r{_})

    debug 'Creating the bgp address family %{name}' % { name: address_family(proto, type) }

    as_number = get_as_number

    cmds = []
    cmds << 'configure terminal'
    cmds << 'router bgp %{as_number}' % { as_number: as_number }
    cmds << 'address-family %{address_family}' % {
      address_family: address_family(proto, type)
    }

    resource_map = self.class.instance_variable_get('@resource_map')
    resource_map.each do |property, options|
      unless @resource[property] == options[:default]
        if @resource[property] == :true
          cmds << ERB.new(options[:template]).result(binding)

        elsif @resource == :false
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

    vtysh(cmds.reduce([]) { |cmdsx, cmd| cmdsx << '-c' << cmd })

    @property_hash[:ensure] = :present
  end

  def destroy
    proto, type = @resource[:name].split(%r{_})

    debug 'Destroying the bgp address family %{address_family}' % { address_family: address_family(proto, type) }

    as_number = get_as_number

    cmds = []
    cmds << 'configure terminal'
    cmds << 'router bgp %{as_number}' % { as_number: as_number }
    cmds << 'address-family %{address_family}' % {
      address_family: address_family(proto, type)
    }

    resource_map = self.class.instance_variable_get('@resource_map')
    resource_map.each do |property, options|
      next if @property_hash[property] == options[:default]

      case options[:type]
      when :array
        @property_hash[property].each do |value|
          cmds << 'no %{command}' % { command: ERB.new(options[:template]).result(binding) }
        end
      when :boolean
        cmds << if @property_hash[property] == :true
                  'no %{command}' % { command: ERB.new(options[:template]).result(binding) }
                else
                  ERB.new(options[:template]).result(binding)
                end
      else
        value = @property_hash[property]
        cmds << 'no %{command}' % { command: ERB.new(options[:template]).result(binding) }
      end
    end

    cmds << 'end'
    cmds << 'write memory'

    vtysh(cmds.reduce([]) { |cmdsx, cmd| cmdsx << '-c' << cmd })

    @property_hash.clear
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def flush
    return if @property_flush.empty?

    proto, type = @resource[:name].split(%r{_})

    debug 'Flushing the bgp address family %{address_family}' % { address_family: address_family(proto, type) }

    as_number = get_as_number

    cmds = []
    cmds << 'configure terminal'
    cmds << 'router bgp %{as_number}' % { as_number: as_number }
    cmds << 'address-family %{address_family}' % {
      address_family: address_family(proto, type)
    }

    resource_map = self.class.instance_variable_get('@resource_map')
    @property_flush.each do |property, v|
      if (v == :absent) || (v == :false)
        cmds << 'no %{command}' % { command: ERB.new(resource_map[property][:template]).result(binding) }

      elsif ((v == :true) || (v == 'true')) && [:symbol, :string].include?(resource_map[property][:type])
        cmds << 'no %{command}' % { comand: ERB.new(resource_map[property][:template]).result(binding) }
        cmds << ERB.new(resource_map[property][:template]).result(binding)

      elsif v == :true
        cmds << ERB.new(resource_map[property][:template]).result(binding)

      elsif resource_map[property][:type] == :array
        (@property_hash[property] - v).each do |value|
          cmds << 'no %{command}' % { command: ERB.new(resource_map[property][:template]).result(binding) }
        end

        (v - @property_hash[property]).each do |value|
          cmds << ERB.new(resource_map[property][:template]).result(binding)
        end

      else
        value = v
        cmds << ERB.new(resource_map[property][:template]).result(binding)
      end
    end

    cmds << 'end'
    cmds << 'write memory'

    vtysh(cmds.reduce([]) { |cmdsx, cmd| cmdsx << '-c' << cmd })

    @property_hash = resource.to_hash
    @property_flush.clear
  end

  def initialize(value)
    super(value)

    @property_flush = {}
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

  def address_family(proto, type)
    proto == 'ipv6' ? proto : "#{proto} #{type}"
  end
end
