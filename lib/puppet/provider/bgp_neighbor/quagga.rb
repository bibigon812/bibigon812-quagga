Puppet::Type.type(:bgp_neighbor).provide :quagga do
  @doc = %q{ Manages bgp neighbors using quagga }

  commands :vtysh => 'vtysh'

  @resource_map = {
      :allow_as_in => {
          :eval => '$1',
          :regexp => /\A\sneighbor\s\S+\sallowas-in\s(\d+)\Z/,
          :template => 'neighbor <%= name %> allowas-in <%= value %>',
          :type => :fixnum,
      },
      :default_originate => {
          :default => :disabled,
          :eval => ':enabled',
          :regexp => /\A\sneighbor\s\S+\sdefault-originate\Z/,
          :template => 'neighbor <%= name %> default-originate',
          :type => :switch,
      },
      :local_as => {
          :eval => '$1',
          :regexp => /\A\sneighbor\s\S+\slocal-as\s(\d+)\Z/,
          :template => 'neighbor <%= name %> local-as <%= value %>',
          :type => :fixnum,
      },
      :next_hop_self => {
          :default => :disabled,
          :eval => ':enabled',
          :regexp => /\A\sneighbor\s\S+\snext-hop-self\Z/,
          :template => 'neighbor <%= name %> next-hop-self',
          :type => :switch,
      },
      :peer_group => {
          :template => 'neighbor <%= name %> peer-group <%= value %>',
          :type => :string,
      },
      :prefix_list_in => {
          :eval => '$1',
          :regexp => /\A\sneighbor\s\S+\sprefix-list\s(\S+)\sin\Z/,
          :template => 'neighbor <%= name %> prefix-list <%= value %> in',
          :type => :string,
      },
      :prefix_list_out => {
          :eval => '$1',
          :regexp => /\A\sneighbor\s\S+\sprefix-list\s(\S+)\sout\Z/,
          :template => 'neighbor <%= name %> prefix-list <%= value %> out',
          :type => :string,
      },
      :remote_as => {
          :eval => '$1',
          :regexp => /\A\sneighbor\s\S+\sremote-as\s(\d+)\Z/,
          :template => 'neighbor <%= name %> remote-as <%= value %>',
          :type => :fixnum,
      },
      :route_map_export => {
          :eval => '$1',
          :regexp => /\A\sneighbor\s\S+\sroute-map\s(\S+)\sexport\Z/,
          :template => 'neighbor <%= name %> route-map <%= value %> export',
          :type => :string,
      },
      :route_map_import => {
          :eval => '$1',
          :regexp => /\A\sneighbor\s\S+\sroute-map\s(\S+)\simport\Z/,
          :template => 'neighbor <%= name %> route-map <%= value %> import',
          :type => :string,
      },
      :route_map_in => {
          :eval => '$1',
          :regexp => /\A\sneighbor\s\S+\sroute-map\s(\S+)\sin\Z/,
          :template => 'neighbor <%= name %> route-map <%= value %> in',
          :type => :string,
      },
      :route_map_out => {
          :eval => '$1',
          :regexp => /\A\sneighbor\s\S+\sroute-map\s(\S+)\sout\Z/,
          :template => 'neighbor <%= name %> route-map <%= value %> out',
          :type => :string,
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

    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|
      next if line =~ /\A!/
      if line =~ /\Arouter\sbgp\s(\d+)\Z/
        as = $1
        found_router = true

      elsif line =~ /\A\sneighbor\s(\S+)\s(peer-group|remote-as)(\s(\S+))?\Z/
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
            hash[property] = options[:default] if options.has_key?(:default)
          end
        end

        hash[key] = value || :enabled

      elsif line =~ /\A\sneighbor\s#{Regexp.escape(name)}\sactivate\Z/
        hash[:ensure] = :activate

      elsif line =~ /\A\sneighbor\s#{Regexp.escape(name)}\sshutdown\Z/
        hash[:ensure] = :shutdown

      elsif line =~ /\A\sneighbor\s#{Regexp.escape(name)}\s/
        @resource_map.each do |property, options|
          if options.has_key?(:regexp)
            if line =~ options[:regexp]

              value = eval(options[:eval])
              hash[property] = case options[:type]
                                 when :fixnum
                                   value.to_i
                                 else
                                   value
                               end
            end
          end
        end

      elsif line =~ /\A\w/ and found_router
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

  def activate
    debug '[activate]'

    @state = @property_hash[:ensure] = :activate
  end

  def create
    debug '[create]'

    resource_map = self.class.instance_variable_get('@resource_map')

    @property_hash[:ensure] = @resource[:ensure]
    @property_hash[:name] = @resource[:name]

    resource_map.each_key do |property|
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
    as, name = @property_hash[:name].split(/:/)

    debug "[flush][#{as}:#{name}]"

    resource_map = self.class.instance_variable_get('@resource_map')

    cmds = []
    cmds << 'configure terminal'
    cmds << "router bgp #{as}"

    if @property_hash[:ensure] == :absent
      @property_flush[:empty] = :absent
      cmds << "no neighbor #{name}"
    else
      unless @state.nil?
        case @state
          when :activate
            cmds << "neighbor #{name} activate"
          when :shutdown
            cmds << "neighbor #{name} shutdown"
          when :present
            cmds << "no neighbor #{name} #{@previous_state}" unless @previous_state.nil?
        end
      end

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

  def shutdown
    debug '[shutdown]'

    @state = @property_hash[:ensure] = :shutdown
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