Puppet::Type.type(:bgp_neighbor).provide :quagga do
  @doc = %q{ Manages bgp neighbors using quagga }

  commands :vtysh => 'vtysh'

  @resource_map = {
      :activate => {
          :default => 'default_ipv4_unicast',
          :value => 'ipv4_unicast',
          :regexp => /\A\s(no\s)?neighbor\s\S+\sactivate\Z/,
          :template => 'neighbor <%= name %> activate',
          :type => :switch,
      },
      :allow_as_in => {
          :default => '1',
          :value => '$1',
          :regexp => /\A\sneighbor\s\S+\sallowas-in\s(\d+)\Z/,
          :template => 'neighbor <%= name %> allowas-in <%= value %>',
          :type => :fixnum,
      },
      :default_originate => {
          :default => ':disabled',
          :value => ':enabled',
          :regexp => /\A\sneighbor\s\S+\sdefault-originate\Z/,
          :template => 'neighbor <%= name %> default-originate',
          :type => :switch,
      },
      :local_as => {
          :value => '$1',
          :regexp => /\A\sneighbor\s\S+\slocal-as\s(\d+)\Z/,
          :template => 'neighbor <%= name %> local-as <%= value %>',
          :type => :fixnum,
      },
      :next_hop_self => {
          :default => ':disabled',
          :value => ':enabled',
          :regexp => /\A\sneighbor\s\S+\snext-hop-self\Z/,
          :template => 'neighbor <%= name %> next-hop-self',
          :type => :switch,
      },
      :passive => {
          :default => ':disabled',
          :value => ':enabled',
          :regexp => /\A\sneighbor\s\S+\spassive\Z/,
          :template => 'neighbor <%= name %> passive',
          :type => :switch,
      },
      :peer_group => {
          :template => 'neighbor <%= name %> peer-group <%= value %>',
          :type => :string,
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
      :remote_as => {
          :value => '$1',
          :regexp => /\A\sneighbor\s\S+\sremote-as\s(\d+)\Z/,
          :template => 'neighbor <%= name %> remote-as <%= value %>',
          :type => :fixnum,
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
          :default => ':disabled',
          :value => ':enabled',
          :regexp => /\A\sneighbor\s\S+\sroute-reflector-client\Z/,
          :template => 'neighbor <%= name %> route-reflector-client',
          :type => :switch,
      },
      :route_server_client => {
          :default => ':disabled',
          :value => ':enabled',
          :regexp => /\A\sneighbor\s\S+\sroute-server-client\Z/,
          :template => 'neighbor <%= name %> route-server-client',
          :type => :switch,
      },
      :shutdown => {
          :default => ':disabled',
          :value => ':enabled',
          :regexp => /\A\sneighbor\s\S+\sshutdown\Z/,
          :template => 'neighbor <%= name %> shutdown',
          :type => :switch,
      },
  }

  def initialize(value)
    super(value)
    @property_flush = {}
    @property_remove = {}
  end

  def self.instances
    debug '[instances]'

    bgp_neighbors = []
    hash = {}
    as = ''
    previous_name = name = ''
    found_router = false
    ipv4_unicast = :disabled
    default_ipv4_unicast = :enabled

    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|
      next if line =~ /\A!/
      if line =~ /\Arouter\sbgp\s(\d+)\Z/
        as = $1
        found_router = true

      elsif found_router && line =~/\A\sno\sbgp\sdefault\sipv4-unicast\Z/
        ipv4_unicast = :enabled
        default_ipv4_unicast = :disabled

      elsif found_router && line =~ /\A\sneighbor\s(\S+)\s(peer-group|remote-as)(\s(\S+))?\Z/
        name = $1
        key = $2
        value = $4

        key = key.gsub(/-/, '_').to_sym
        value = value.to_i if key == :remote_as

        unless name == previous_name
          unless hash.empty?
            debug "bgp_neighbor: #{hash}"
            bgp_neighbors << new(hash)
          end
          hash = {}
          hash[:provider] = self.name
          hash[:name] = "#{as}:#{name}"
          hash[:ensure] = :present

          @resource_map.each do |property, options|
            hash[property] = eval(options[:default]) if options.has_key?(:default)
          end
        end

        hash[key] = value || :enabled

      elsif found_router && line =~ /\A\sneighbor\s#{Regexp.escape(name)}\s/
        @resource_map.each do |property, options|
          if options.has_key?(:regexp)
            if line =~ options[:regexp]

              value = eval(options[:value])
              hash[property] = case options[:type]
                                 when :fixnum
                                   value.to_i
                                 else
                                   value
                               end
            end
          end
        end

      elsif found_router && line =~ /\A\w/
        break
      end

      previous_name = name
    end

    unless hash.empty?
      debug "bgp_neighbor: #{hash}"
      bgp_neighbors << new(hash)
    end

    bgp_neighbors
  end

  def self.prefetch(resources)
    providers = instances
    found_providers = []
    resources.each_key do |name|
      if provider = providers.find { |provider| provider.name == name }
        resources[name].provider = provider
        found_providers << provider
        provider.purge
      end
    end
    (providers - found_providers).each { |provider| provider.destroy }
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
    debug '[destroy]'

    @property_hash[:ensure] = :absent
    flush
  end

  def exists?
    @property_hash[:ensure] != :absent
  end

  def flush
    as, name = (@property_hash[:name].nil? ? @resource[:name] : @property_hash[:name]).split(/:/)

    debug "[flush][#{as}:#{name}]"

    resource_map = self.class.instance_variable_get('@resource_map')

    cmds = []
    cmds << 'configure terminal'
    cmds << "router bgp #{as}"

    if @property_hash[:ensure] == :absent
      @property_flush[:empty] = :absent
      cmds << "no neighbor #{name}"
    else
      @property_remove.each do |property, value|
        cmds << "no #{ERB.new(resource_map[property][:template]).result(binding)}"
      end

      @property_flush.each do |property, value|
        cmd = ''
        if resource_map[property][:type] == :switch && value == :disabled
          cmd << 'no '
        end
        cmd << ERB.new(resource_map[property][:template]).result(binding)
        cmds << cmd
      end
    end

    cmds << 'end'
    cmds << 'write memory'

    unless @property_flush.empty? && @property_remove.empty?
      vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })
      @property_flush.clear
      @property_remove.clear
    end
  end

  def purge
    debug '[purge]'

    resource_map = self.class.instance_variable_get('@resource_map')

    unless @resource[:ensure] == @property_hash[:ensure]
      @state = @resource[:ensure]
      @previous_state = @property_hash[:ensure]
      debug "New state: #{@state}"
    end

    resource_map.each_key do |property|
      if @resource[property].nil? && !@property_hash[property].nil?
        @property_remove[property] = @property_hash[property]
      end
    end

    flush
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