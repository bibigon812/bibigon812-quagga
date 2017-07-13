Puppet::Type.type(:quagga_bgp_peer_address_family).provide :quagga do
  @doc = 'Manages the address family of bgp peers using quagga.'

  confine :osfamily => :redhat

  commands :vtysh => 'vtysh'

  @resource_map = {
    :peer_group => {
      :default => :false,
      :regexp => /\A\sneighbor\s(\S+)\speer-group(?:\s(\w+))?\Z/,
      :template => 'neighbor <%= name %> peer-group<% unless value.nil? %> <%= value %><% end %>',
      :type => :string,
    },
    :activate => {
      :regexp => /\A\s(?:(no)\s)?neighbor\s(\S+)\sactivate\Z/,
      :template => 'neighbor <%= name %> activate',
      :type => :boolean,
    },
    :allow_as_in => {
      :default => :absent,
      :regexp => /\A\sneighbor\s(\S+)\sallowas-in\s(\d+)\Z/,
      :template => 'neighbor <%= name %> allowas-in<% unless value.nil? %> <%= value %><% end %>',
      :type => :fixnum,
    },
    :default_originate => {
      :default => :false,
      :regexp => /\A\sneighbor\s(\S+)\sdefault-originate\Z/,
      :template => 'neighbor <%= name %> default-originate',
      :type => :boolean,
    },
    :next_hop_self => {
      :default => :false,
      :regexp => /\A\sneighbor\s(\S+)\snext-hop-self\Z/,
      :template => 'neighbor <%= name %> next-hop-self',
      :type => :boolean,
    },
    :prefix_list_in => {
      :default => :absent,
      :regexp => /\A\sneighbor\s(\S+)\sprefix-list\s(\S+)\sin\Z/,
      :template => 'neighbor <%= name %> prefix-list <%= value %> in',
      :type => :string,
    },
    :prefix_list_out => {
      :default => :absent,
      :regexp => /\A\sneighbor\s(\S+)\sprefix-list\s(\S+)\sout\Z/,
      :template => 'neighbor <%= name %> prefix-list <%= value %> out',
      :type => :string,
    },
    :route_map_export => {
      :default => :absent,
      :regexp => /\A\sneighbor\s(\S+)\sroute-map\s(\S+)\sexport\Z/,
      :template => 'neighbor <%= name %> route-map <%= value %> export',
      :type => :string,
    },
    :route_map_import => {
      :default => :absent,
      :regexp => /\A\sneighbor\s(\S+)\sroute-map\s(\S+)\simport\Z/,
      :template => 'neighbor <%= name %> route-map <%= value %> import',
      :type => :string,
    },
    :route_map_in => {
      :default => :absent,
      :regexp => /\A\sneighbor\s(\S+)\sroute-map\s(\S+)\sin\Z/,
      :template => 'neighbor <%= name %> route-map <%= value %> in',
      :type => :string,
    },
    :route_map_out => {
      :default => :absent,
      :regexp => /\A\sneighbor\s(\S+)\sroute-map\s(\S+)\sout\Z/,
      :template => 'neighbor <%= name %> route-map <%= value %> out',
      :type => :string,
    },
    :route_reflector_client => {
      :default => :false,
      :regexp => /\A\sneighbor\s(\S+)\sroute-reflector-client\Z/,
      :template => 'neighbor <%= name %> route-reflector-client',
      :type => :boolean,
    },
    :route_server_client => {
      :default => :false,
      :regexp => /\A\sneighbor\s(\S+)\sroute-server-client\Z/,
      :template => 'neighbor <%= name %> route-server-client',
      :type => :boolean,
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
    default_ipv4_unicast = :true
    peer_group_af_activate = {}
    found_activate = false

    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|
      # Skipping comments
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
              peer = $2
              value = $1
            else
              peer = $1
              value = $2
            end

            unless peer == previous_peer
              unless hash.empty?
                # Adding the value of the property `activate` if it's not found.
                unless found_activate
                  if [:true, :false].include?(hash[:peer_group])
                    hash[:activate] = address_family == :ipv4_unicast ? default_ipv4_unicast : :false
                  else
                    hash[:activate] = peer_group_af_activate[hash[:peer_group]]
                  end
                end

                # Saving the value of the property `activate` if the resource is a peer group.
                peer_group_af_activate[previous_peer] = hash[:activate] if hash[:peer_group] == :true

                debug 'Instantiated the bgp peer address family %{name}.' % { :name => hash[:name] }

                providers << new(hash)
              end

              hash = {
                :ensure => :present,
                :name => "#{peer} #{address_family}",
                :provider => self.name,
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
      # Adding the value of the property `activate` if it's not found.
      unless found_activate
        if [:true, :false].include?(hash[:peer_group])
          hash[:activate] = address_family == :ipv4_unicast ? default_ipv4_unicast : :false
        else
          hash[:activate] = peer_group_af_activate[hash[:peer_group]]
        end
      end

      debug 'Instantiated the bgp peer address family %{name}.' % { :name => hash[:name] }

      providers << new(hash)
    end

    providers
  end

  def self.prefetch(resources)
    providers = instances
    resources.keys.each do |name|
      if provider = providers.find{ |provider| provider.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
    name, address_family = @resource[:name].split(/\s/)

    debug 'Creating the address family %{address_family} of the bgp peer %{peer}' % {
      :address_family => address_family,
      :peer => name,
    }

    as_number = get_as_number
    resource_map = self.class.instance_variable_get('@resource_map')

    cmds = []
    cmds << 'configure terminal'
    cmds << 'router bgp %{as_number}' % { :as_number => as_number}
    cmds << 'address-family %{address_family}' % {
      :address_family => address_family_to_s(address_family)
    }

    resource_map.each do |property, options|
      if @resource[property] and @resource[property] != options[:default]
        if @resource[property] == :true
          cmds << ERB.new(options[:template]).result(binding)

        elsif @resource[property] == :false
          cmds << 'no %{command}' % { :command => ERB.new(options[:template]).result(binding) }

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

    vtysh(cmds.reduce([]){ |commands, command| commands << '-c' << command })
  end

  def destroy
    name, address_family = @property_hash[:name].split(/\s/)

    debug 'Destroying the address family %{address_family} of the bgp peer %{peer}' % {
      :address_family => address_family,
      :peer => name,
    }

    as_number = get_as_number
    resource_map = self.class.instance_variable_get('@resource_map')

    cmds = []
    cmds << 'configure terminal'
    cmds << 'router bgp %{as_number}' % { :as_number => as_number}
    cmds << 'address-family %{address_family}' % {
      :address_family => address_family_to_s(address_family)
    }

    resource_map.each do |property, options|
      unless @property_hash[property] == options[:default]
        if @property_hash[property] == :true or property == :allow_as_in
          cmds << 'no %{command}' % { :command => ERB.new(resource_map[property][:template]).result(binding) }

        elsif options[:type] == :array
          @property_hash[property].each do |value|
            cmds << 'no %{command}' % { :command => ERB.new(resource_map[property][:template]).result(binding) }
          end

        else
          value = @property_hash[property]
          cmds << 'no %{command}' % { :command => ERB.new(resource_map[property][:template]).result(binding) }
        end
      end
    end

    cmds << 'end'
    cmds << 'write memory'

    vtysh(cmds.reduce([]){ |commands, command| commands << '-c' << command })

    @property_hash.clear
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def flush
    return if @property_flush.empty?

    name, address_family = @property_hash[:name].split(/\s/)

    debug 'Flushing the address family %{address_family} of the bgp peer %{peer}' % {
      :address_family => address_family,
      :peer => name,
    }

    as_number = get_as_number
    resource_map = self.class.instance_variable_get('@resource_map')

    cmds = []
    cmds << 'configure terminal'
    cmds << 'router bgp %{as_number}' % { :as_number => as_number }
    cmds << 'address-family %{address_family}' % {
      :address_family => address_family_to_s(address_family)
    }

    @property_flush.each do |property, v|
      if v == :absent or v == :false
        if [:prefix_list_in, :prefix_list_out, :route_map_export,
          :route_map_import, :route_map_in, :route_map_out, :peer_group].include?(property)
          value = @property_hash[property]
        end

        cmds << 'no %{command}' % { :command => ERB.new(resource_map[property][:template]).result(binding) }

      elsif v == :true and [:symbol, :string].include?(resource_map[property][:type])
        cmds << 'no %{command}' % { :command => ERB.new(resource_map[property][:template]).result(binding) }
        cmds << ERB.new(resource_map[property][:template]).result(binding)

      elsif v == :true
        cmds << ERB.new(resource_map[property][:template]).result(binding)

      elsif resource_map[property][:type] == :array
        (@property_hash[property] - v).each do |value|
          cmds << 'no %{command}' % { :command => ERB.new(resource_map[property][:template]).result(binding) }
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

    vtysh(cmds.reduce([]) { |commands, command| commands << '-c' << command })

    @property_hash = @resource.to_hash
    @property_flush.clear
  end

  @resource_map.each_key do |property|
    define_method "#{property}" do
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
        vtysh('-c', 'show running-config').split(/\n/).collect.each do |line|
          if line =~ /\Arouter\sbgp\s(\d+)\Z/
            @as_number = Integer($1)
            break
          end
        end
      rescue
      end
    end

    @as_number
  end

  def address_family_to_s(address_family)
    address_family == 'ipv6_unicast' ? 'ipv6' : address_family.gsub('_', ' ')
  end
end
