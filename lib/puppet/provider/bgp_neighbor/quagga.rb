Puppet::Type.type(:bgp_neighbor).provide(:quagga) do
  @doc = %q{ Manages bgp neighbors using quagga }

  commands :vtysh => 'vtysh'

  @resource_map = {
      :peer_group => {
          :value => '$1',
          :template => 'neighbor <%= name %> peer-group <%= value %>',
          :type => :string,
      },
      :remote_as => {
          :value => '$1',
          :regexp => /\A\sneighbor\s\S+\sremote-as\s(\d+)\Z/,
          :template => 'neighbor <%= name %> remote-as <%= value %>',
          :type => :fixnum,
      },
      :activate => {
          :regexp => /\A\s(no\s)?neighbor\s\S+\sactivate\Z/,
          :template => 'neighbor <%= name %> activate',
          :type => :boolean,
      },
      :allow_as_in => {
          :value => '$1',
          :regexp => /\A\sneighbor\s\S+\sallowas-in\s(\d+)\Z/,
          :template => 'neighbor <%= name %> allowas-in <%= value %>',
          :remove_template => 'no neighbor <%= name %> allowas-in',
          :type => :fixnum,
      },
      :default_originate => {
          :default => ':false',
          :value => ':true',
          :regexp => /\A\sneighbor\s\S+\sdefault-originate\Z/,
          :template => 'neighbor <%= name %> default-originate',
          :type => :boolean,
      },
      :local_as => {
          :value => '$1',
          :regexp => /\A\sneighbor\s\S+\slocal-as\s(\d+)\Z/,
          :template => 'neighbor <%= name %> local-as <%= value %>',
          :type => :fixnum,
      },
      :next_hop_self => {
          :default => ':false',
          :value => ':true',
          :regexp => /\A\sneighbor\s\S+\snext-hop-self\Z/,
          :template => 'neighbor <%= name %> next-hop-self',
          :type => :boolean,
      },
      :passive => {
          :default => ':false',
          :value => ':true',
          :regexp => /\A\sneighbor\s\S+\spassive\Z/,
          :template => 'neighbor <%= name %> passive',
          :type => :boolean,
      },
      :prefix_list_in => {
          :value => '$1',
          :regexp => /\A\sneighbor\s\S+\sprefix-list\s(\S+)\sin\Z/,
          :template => 'neighbor <%= name %> prefix-list <%= value %> in',
          :type => :string,
      },
      :prefix_list_out => {
          :value => '$1',
          :regexp => /\A\sneighbor\s\S+\sprefix-list\s(\S+)\sout\Z/,
          :template => 'neighbor <%= name %> prefix-list <%= value %> out',
          :type => :string,
      },
      :route_map_export => {
          :value => '$1',
          :regexp => /\A\sneighbor\s\S+\sroute-map\s(\S+)\sexport\Z/,
          :template => 'neighbor <%= name %> route-map <%= value %> export',
          :type => :string,
      },
      :route_map_import => {
          :value => '$1',
          :regexp => /\A\sneighbor\s\S+\sroute-map\s(\S+)\simport\Z/,
          :template => 'neighbor <%= name %> route-map <%= value %> import',
          :type => :string,
      },
      :route_map_in => {
          :value => '$1',
          :regexp => /\A\sneighbor\s\S+\sroute-map\s(\S+)\sin\Z/,
          :template => 'neighbor <%= name %> route-map <%= value %> in',
          :type => :string,
      },
      :route_map_out => {
          :value => '$1',
          :regexp => /\A\sneighbor\s\S+\sroute-map\s(\S+)\sout\Z/,
          :template => 'neighbor <%= name %> route-map <%= value %> out',
          :type => :string,
      },
      :route_reflector_client => {
          :default => ':false',
          :value => ':true',
          :regexp => /\A\sneighbor\s\S+\sroute-reflector-client\Z/,
          :template => 'neighbor <%= name %> route-reflector-client',
          :type => :boolean,
      },
      :route_server_client => {
          :default => ':false',
          :value => ':true',
          :regexp => /\A\sneighbor\s\S+\sroute-server-client\Z/,
          :template => 'neighbor <%= name %> route-server-client',
          :type => :boolean,
      },
      :shutdown => {
          :default => ':false',
          :value => ':true',
          :regexp => /\A\sneighbor\s\S+\sshutdown\Z/,
          :template => 'neighbor <%= name %> shutdown',
          :type => :boolean,
      },
      :update_source => {
          :value => '$1',
          :regexp => /\A\sneighbor\s\S+\supdate-source\s(\S+)\Z/,
          :template => 'neighbor <%= name %> update-source <%= value %>',
          :type => :string,
      },
  }

  def initialize(value)
    super(value)
    @property_flush = {}
  end

  def self.instances
    debug '[instances]'

    providers = []

    hash = {}
    activate = {}

    as = ''
    previous_name = name = ''
    found_router = false

    default_ipv4_unicast = :true

    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|
      next if line =~ /\A!/
      if line =~ /\Arouter\sbgp\s(\d+)\Z/
        as = $1
        found_router = true

      # I store a default value of the property `ipv4_unicast`
      elsif found_router && line =~/\A\sno\sbgp\sdefault\sipv4-unicast\Z/
        default_ipv4_unicast = :false

      elsif found_router && line =~ /\A\sneighbor\s(\S+)\s(peer-group|remote-as)(\s(\S+))?\Z/
        name = $1
        key = $2
        value = $4

        key = key.gsub(/-/, '_').to_sym
        value = value.to_i if key == :remote_as

        unless name == previous_name
          unless hash.empty?
            unless hash.include?(:activate)
              hash[:activate] = (activate[hash[:peer_group]].nil? ? default_ipv4_unicast : activate[hash[:peer_group]])
            end

            debug "bgp_neighbor: #{hash}"

            if hash[:peer_group]
              # If it's peer_group I store a activate value.
              activate[previous_name] = hash[:activate]
            end

            providers << new(hash)
          end

          hash = {}
          hash[:provider] = self.name
          hash[:name] = "#{as} #{name}"
          hash[:ensure] = :present

          # I add defult values
          @resource_map.each do |property, options|
            next if property == :activate
            hash[property] = eval(options[:default]) if options.has_key?(:default)
          end
        end

        hash[key] = value.nil? ? :true : value

      elsif found_router && line =~ /\A\s(no\s)?neighbor\s#{Regexp.escape(name)}\s/
        @resource_map.each do |property, options|
          if options.has_key?(:regexp)
            if line =~ options[:regexp]

              if property == :activate
                hash[:activate] = case (activate[hash[:peer_group]].nil? ? default_ipv4_unicast : activate[hash[:peer_group]])
                                    when :true
                                      :false
                                    else
                                      :true
                                  end

              else
                value = eval(options[:value])
                hash[property] = case options[:type]
                                   when :fixnum
                                     value.to_i
                                   else
                                     value
                                 end
              end

              break
            end
          end
        end

      elsif found_router && line =~ /\A\w/
        break
      end

      previous_name = name
    end

    unless hash.empty?
      unless hash.include?(:activate)
        hash[:activate] = activate[hash[:peer_group]].nil? ? default_ipv4_unicast : activate[hash[:peer_group]]
      end

      debug "bgp_neighbor: #{hash}"

      providers << new(hash)
    end

    providers
  end

  def self.prefetch(resources)
    providers = instances
    found_providers = []
    resources.each_key do |name|
      if provider = providers.find { |provider| provider.name == name }
        resources[name].provider = provider
        found_providers << provider
      end
    end
  end

  def create
    debug '[create]'

    resource_map = self.class.instance_variable_get('@resource_map')

    @property_hash[:ensure] = :present
    @property_hash[:name] = @resource[:name]

    resource_map.keys.each do |property|
      self.method("#{property}=").call(@resource[property]) unless @resource[property].nil?
    end
  end


  def destroy
    as, name = @property_hash[:name].split(/\s+/)

    debug "[destroy][#{as} #{name}]"

    cmds = []
    cmds << 'configure terminal'
    cmds << "router bgp #{as}"
    cmds << "no neighbor #{name}"
    cmds << 'end'
    cmds << 'write memory'

    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })

    @property_hash.clear
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def flush
    # as, name = (@property_hash[:name].nil? ? @resource[:name] : @property_hash[:name]).split(/\s+/)
    as, name = @property_hash[:name].split(/\s+/)

    debug "[flush][#{as} #{name}]"

    resource_map = self.class.instance_variable_get('@resource_map')

    cmds = []
    cmds << 'configure terminal'
    cmds << "router bgp #{as}"

    @property_flush.each do |property, value|
      cmd = ''
      if resource_map[property][:type] == :boolean && value == :false
        cmd << 'no '
      end
      value = nil if property == :peer_group && (value == :true || value == :false)
      cmd << ERB.new(resource_map[property][:template]).result(binding)
      cmds << cmd
    end

    cmds << 'end'
    cmds << 'write memory'

    unless @property_flush.empty?
      vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })
      @property_flush.clear
    end
  end

  def reset
    as, name = @property_hash[:name].split(/\s+/)
    debug "[reset][#{as} #{name}]"

    cmds = []
    proto = name.include?('.') ? 'ip' : 'ipv6'
    cmds << "clear #{proto} bgp #{name} soft"

    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })
  end

  @resource_map.each_key do |property|
    define_method "#{property}" do
      @property_hash[property] || :absent
    end

    define_method "#{property}=" do |value|
      @property_flush[property] = value
    end
  end
end