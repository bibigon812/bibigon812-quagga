Puppet::Type.type(:quagga_static_route).provide :quagga do
  @doc = %q{ Manages static routes using zebra }

  @resource_properties = [
      :nexthop,
      :distance,
  ]

  @template = 'ip route <%= prefix %> <%= nexthop %><% unless option.nil? %> <%= option %><% end %><% unless distance.nil? %> <%= distance %><% end %>'

  commands :vtysh => 'vtysh'

  mk_resource_methods

  def self.instances
    providers = []
    found_route = false

    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|

      if line =~ /\Aip\sroute\s(\S+)\s(\S+)(?:\s(blackhole|reject))?(?:\s(\d+))?\Z/

        prefix = $1
        nexthop = $2
        option = $3.nil? ? :absent : $3.to_sym
        distance = $4.nil? ? :absent : Integer($4)

        hash = {
            :prefix   => prefix,
            :ensure   => :present,
            :nexthop  => nexthop,
            :distance => distance,
            :option   => option,
            :provider => self.name,
        }

        providers << new(hash)

        found_route = true

      elsif line =~ /\A\w/ and found_route
        break
      end
    end

    providers
  end

  def self.prefetch(resources)
    providers = instances
    resources.keys.each do |name|
      if provider = providers.find{ |provider| provider.prefix == resources[name][:prefix] and provider.nexthop == resources[name][:nexthop] }
        resources[name].provider = provider
      end
    end
  end

  def create
    template = self.class.instance_variable_get('@template')
    prefix = @resource[:prefix]

    debug 'Creating the route to %{prefix}.' % { :prefix => prefix }

    cmds = []
    cmds << 'configure terminal'

    distance = @resource[:distance] unless @resource[:distance] == :absent
    nexthop = @resource[:nexthop] unless @resource[:nexthop] == :absent
    option = @resource[:option] unless @resource[:option] == :absent

    cmds << ERB.new(template).result(binding)

    cmds << 'end'
    cmds << 'write memory'
    vtysh(cmds.reduce([]){ |commands, command| commands << '-c' << command })

    @property_hash = @resource.to_hash
  end

  def destroy
    template = self.class.instance_variable_get('@template')
    prefix = @property_hash[:prefix]

    debug 'Destroying the route to %{prefix}.' % { :prefix => prefix }

    cmds = []
    cmds << 'configure terminal'

    distance = @property_hash[:distance] unless @property_hash[:distance] == :absent
    nexthop = @property_hash[:nexthop] unless @property_hash[:nexthop] == :absent
    option = @property_hash[:option] unless @property_hash[:option] == :absent

    cmds << 'no %{command}' % { :command => ERB.new(template).result(binding) }

    cmds << 'end'
    cmds << 'write memory'
    vtysh(cmds.reduce([]){ |commands, command| commands << '-c' << command })

    @property_hash.clear
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def distance=(value)
    create
  end

  def option=(value)
    destroy
    create
  end

  def name
    "#{prefix} #{nexthop}"
  end
end
