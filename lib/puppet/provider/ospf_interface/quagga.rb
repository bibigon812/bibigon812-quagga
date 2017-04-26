Puppet::Type.type(:ospf_interface).provide :quagga do
  @doc = %q{Manages the interface ospf parameters using quagga}

  @resource_map = {
    :cost                 => { :config => 'cost', :default => 10, },
    :dead_interval        => { :config => 'dead-interval', :default => 40 },
    :hello_interval       => { :config => 'hello-interval', :default => 10 },
    :mtu_ignore           => { :config => 'mtu-ignore', :default => :disable },
    :network              => { :config => 'network' },
    :priority             => { :config => 'priority', :default => 1 },
    :retransmit_interval  => { :config => 'retransmit-interval', :default => 5 },
    :transmit_delay       => { :config => 'transmit-delay', :default => 1 }
  }

  @known_booleans = [
    :mtu_ignore,
  ]

  commands :vtysh => 'vtysh'

  mk_resource_methods

  def initialize(value)
    super(value)
    @property_flush = {}
    @property_remove = {}
  end

  def self.instances
    ospf_interfaces = []
    debug '[instances]'
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
          hash[:mtu_ignore] = :enable
        else
          hash[:mtu_ignore] = :disable
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
        provider.flush
      end
    end
    (providers - found_providers).each do |provider|
      provider.destroy
    end
  end

  def create
    resource_map = self.class.instance_variable_get('@resource_map')

    @property_hash[:ensure] = :present

    resource_map.keys.each do |property|
      @property_flush[property] = @resource[property] unless @resource[property].nil?
    end
  end

  def destroy
    resource_map = self.class.instance_variable_get('@resource_map')

    @property_hash[:ensure] = :absent

    resource_map.keys.each do |property|
      unless @property_hash[property].nil? || @property_hash[property] == resource_map[property][:default]
        @property_remove[property] = @property_hash[property]
      end
    end

    flush unless @property_remove.empty?
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def flush
    resource_map = self.class.instance_variable_get('@resource_map')
    name = @property_hash[:name].nil? ? @resource[:name] : @property_hash[:name]

    debug "[flush][#{name}]"

    cmds = []
    cmds << 'configure terminal'
    cmds << "interface #{name}"

    @property_remove.keys.each do |property|
      debug "The #{property} property has been removed"

      cmds << "no ip ospf #{resource_map[property][:config]}"
    end

    @property_flush.each do |property, value|
      debug "The #{property} property has been changed from #{@property_hash[property]} to #{value}"

      cmd = "ip ospf"
      case value
        when :disable
          cmds << "no ip ospf #{resource_map[property][:config]}"
        when :enable
          cmds << "ip ospf #{resource_map[property][:config]}"
        else
          cmds << "ip ospf #{resource_map[property][:config]} #{value}"
      end
    end

    cmds << "end"
    cmds << "write memory"
    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })
  end

  def purge
    debug '[purge]'
    resource_map = self.class.instance_variable_get('@resource_map')

    resource_map.keys.each do |property|
      if (!@property_hash[property].nil?) && @resource[property].nil?
        @property_remove[property] = @property_hash[property]
      end
    end

    flush unless @property_remove.empty?
  end

  @resource_map.keys.each do |property|
    define_method "#{property}" do
      @property_hash[property] || :absent
    end

    define_method "#{property}=" do |value|
      @property_flush[property] = value
    end
  end
end
