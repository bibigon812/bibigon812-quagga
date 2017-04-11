Puppet::Type.type(:ospf_interface).provide :quagga do
  @doc = %q{Manages the interface ospf parameters using quagga}

  @resource_map = {
    :cost                 => 'cost',
    :dead_interval        => 'dead-interval',
    :hello_interval       => 'hello-interval',
    :mtu_ignore           => 'mtu-ignore',
    :network_type         => 'network',
    :priority             => 'priority',
    :retransmit_interval  => 'retransmit-interval',
    :transmit_delay       => 'transmit-delay',
  }

  @known_booleans = [
    :mtu_ignore,
  ]

  commands :vtysh => 'vtysh'

  def initialize value={}
    super(value)
    @property_flush = {}
  end

  def self.instances
    ospf_interfaces = []
    debug 'Creating instances of OSPF interfaces'
    hash = {}
    config = vtysh('-c', 'show ip ospf interface')
    config.split(/\n/).collect do |line|
      if line =~ /\A([\w\d\.]+) .*\Z/
        name = $1
        unless hash.empty?
          ospf_interfaces << new(hash)
        end
        hash = {}
        hash[:name] = name
        hash[:provider] = self.name
        hash[:ensure] = :enabled
      elsif line =~ /\A\s+OSPF not enabled on this interface\Z/
        hash[:ensure] = :disabled
      elsif line =~ /\A\s+MTU mismatch detection:(\w+)\Z/
        case $1
        when 'disabled'
          hash[:mtu_ignore] = :true
        else
          hash[:mtu_ignore] = :false
        end
      elsif line =~ /\A\s+Router\s+ID\s+(\d+\.\d+\.\d+\.\d+),\s+Network\s+Type\s+(\w+),\s+Cost:\s+(\d+)\Z/
        network_type = $2
        cost = $3
        hash[:network_type] = network_type.downcase.gsub(/-/, '_').to_sym
        hash[:cost] = cost.to_i
      elsif line =~ /\A\s+Transmit\s+Delay\s+is\s+(\d+)\s+sec,\s+State\s+(\w+),\s+Priority\s+(\d+)\Z/
        transmit_delay = $1
        priority = $3
        hash[:transmit_delay] = transmit_delay.to_i
        hash[:priority] = priority.to_i
      elsif line =~ /\A\s+Timer\s+intervals\s+configured,\s+Hello\s+(\d+)s,\s+Dead\s+(\d+)s,\sWait\s+(\d+)s,\s+Retransmit\s+(\d)\Z/
        hello_interval = $1
        dead_interval = $2
        retransmit_interval = $4
        hash[:hello_interval] = hello_interval.to_i
        hash[:dead_interval] = dead_interval.to_i
        hash[:retransmit_interval] = retransmit_interval.to_i
      end
    end
    ospf_interfaces << new(hash)
    ospf_interfaces
  end

  def self.prefetch(resources)
    providers = instances
    found_providers = []
    resources.keys.each do |name|
      if provider = providers.find { |provider| provider.name == name }
        resources[name].provider = provider
        provider.purge
        found_providers << provider
      end
    end
    (providers - found_providers).each do |provider|
      provider.destroy
    end
  end

  def create
    debug 'Appling OSPF parameters for interface: %s' % @resource[:name]

    resource_map = self.class.instance_variable_get('@resource_map')

    @property_hash[:needs_change] ||= []
    resource_map.each_key do |property|
      unless @resource[property].nil?
        @property_hash[:needs_change] << property
      end
    end
    @property_hash[:name] = @resource[:name]
    @property_hash[:ensure] = :present
  end

  def destroy
    debug 'Reseting OSPF parameters for interface: %s' % @property_hash[:name]

    resource_map = self.class.instance_variable_get('@resource_map')

    cmds = []
    cmds << "configure terminal"
    cmds << "interface #{@property_hash[:name]}"
    resource_map.each_value do |cmd|
      cmds << "no ip ospf #{cmd}"
    end
    cmds << "end"
    cmds << "write memory"

    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })

    @property_hash.clear
  end



  def exists?
    @property_hash[:ensure] == :present
  end

  def flush
    return if @property_hash[:needs_change].nil? or @property_hash[:needs_change].empty?

    debug 'Flushing OSPF parameters for interface: %s' % @property_hash[:name]

    resource_map = self.class.instance_variable_get('@resource_map')
    known_booleans = self.class.instance_variable_get('@known_booleans')

    cmds = []
    cmds << ['configure', 'terminal'].join(' ')
    cmds << ['interface', @property_hash[:name]].join(' ')
    @property_hash[:needs_change].each do |property|
      if known_booleans.include?(property)
        if @resource[property].to_sym == :true
          cmds << ['ip', 'ospf', resource_map[property]].join(' ')
        elsif @resource[property].to_sym == :false
          cmds << ['no', 'ip', 'ospf', resource_map[property]].join(' ')
        end
      else
        cmds << ['ip', 'ospf', resource_map[property], @resource[property]].join(' ')
      end
      @property_hash[property] = @resource[property]
    end
    cmds << 'end'
    cmds << 'write memory'
    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })

    @property_hash[:needs_change].clear
  end

  def purge
    debug 'Removing unused parameters'

    resource_map = self.class.instance_variable_get('@resource_map')
    needs_purge = false

    cmds = []
    cmds << "configure terminal"
    cmds << "interface #{@property_hash[name]}"
    @property_hash.each do |property, value|
      if @resource[property].nil?
        cmds << "no ip ospf #{resource_map[property]}"
        needs_purge = true
      end
    end
    cmds << "end"
    cmds << "write memory"

    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd }) if needs_purge
  end

  @resource_map.keys.each do |property|
    if @known_booleans.include?(property)
      define_method "#{property}" do
        @property_hash[property] || :false
      end
    else
      define_method "#{property}" do
        @property_hash[property] || :absent
      end
    end

    define_method "#{property}=" do |value|
      @property_flush[property] = value
    end
  end
end
