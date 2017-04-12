Puppet::Type.type(:ospf_interface).provide :quagga do
  @doc = %q{Manages the interface ospf parameters using quagga}

  @resource_map = {
    :cost                 => 'cost',
    :dead_interval        => 'dead-interval',
    :hello_interval       => 'hello-interval',
    :mtu_ignore           => 'mtu-ignore',
    :network              => 'network',
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
      if line =~ /\A([\w\d\.]+) is (up|down)\Z/
        name = $1
        unless hash.empty?
          debug "OSPF #{hash[:ensure]} on #{hash[:name]}"
          ospf_interfaces << new(hash) if hash[:ensure] == :present
        end
        hash = {}
        hash[:name] = name
        hash[:provider] = self.name
        hash[:ensure] = :present
      elsif line =~ /\A\s+OSPF not enabled on this interface\Z/
        hash[:ensure] = :absent
      elsif line =~ /\A\s+MTU mismatch detection:(\w+)\Z/
        case $1
        when 'disabled'
          hash[:mtu_ignore] = :true
        else
          hash[:mtu_ignore] = :false
        end
      elsif line =~ /\A\s+Router\s+ID\s+(\d+\.\d+\.\d+\.\d+),\s+Network\s+Type\s+(\w+),\s+Cost:\s+(\d+)\Z/
        network = $2
        cost = $3
        hash[:network] = network.downcase.gsub(/-/, '_').to_sym
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
    ospf_interfaces << new(hash) if hash[:ensure] == :present
    ospf_interfaces
  end

  def self.prefetch(resources)
    providers = instances
    found_providers = []
    resources.keys.each do |name|
      if provider = providers.find { |provider| provider.name == name }
        resources[name].provider = provider
        found_providers << provider
      end
    end
  end

  def create
    debug 'Enabling OSPF for interface: %s' % @resource[:name]
    @property_flush[:ensure] = :enabled
  end

  def destroy
    debug 'Disabling OSPF for interface: %s' % @property_hash[:name]
    @property_flush[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def flush
    debug 'Flushing changes'

    if @property_flush[:ensure] == :absent
      @property_flush.clear
      @property_hash.clear
      return
    end

    resource_map = self.class.instance_variable_get('@resource_map')

    cmds = []
    cmds << "configure terminal"
    cmds << "interface #{@property_hash[:name]}"

    @property_flush.each do |property, value|
      if value.to_sym == :true
        cmds << "ip ospf #{resource_map[property]}"
      elsif value.to_sym == :false
        cmds << "no ip ospf #{resource_map[property]}"
      else
        cmds << "ip ospf #{resource_map[property]} #{value}"
      end
      @property_hash[property] = value
    end
    @property_flush.clear

    cmds << "end"
    cmds << "write memory"
    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })
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
