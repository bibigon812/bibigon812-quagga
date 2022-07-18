Puppet::Type.type(:quagga_static_route).provide :quagga do
  @doc = ' Manages static routes using zebra '

  @template = 'ip route <%= prefix %> <%= nexthop %><% unless option.nil? %> <%= option %><% end %><% unless distance.nil? %> <%= distance %><% end %>'

  commands vtysh: 'vtysh'

  mk_resource_methods

  def self.instances
    providers = []
    found_route = false

    config = vtysh('-c', 'show running-config')
    config.split(%r{\n}).map do |line|
      if line =~ %r{\Aip\sroute\s(\S+)\s(\S+)(?:\s(blackhole|reject))?(?:\s(\d+))?\Z}

        prefix = Regexp.last_match(1)
        nexthop = Regexp.last_match(2)
        option = Regexp.last_match(3).nil? ? :absent : Regexp.last_match(3).to_sym
        distance = Regexp.last_match(4).nil? ? :absent : Integer(Regexp.last_match(4))

        hash = {
          prefix:   prefix,
            ensure:   :present,
            nexthop:  nexthop,
            distance: distance,
            option:   option,
            provider: name,
        }

        debug 'Instantiated the resource %{hash}' % { hash: hash.inspect }
        providers << new(hash)

        found_route = true

      elsif line =~ (%r{\A\w}) && found_route
        break
      end
    end

    providers
  end

  def self.prefetch(resources)
    instances.each do |provider|
      if (resource = resources[provider.name])
        debug 'Prefetched the resource %{resource}' % { resource: resource.to_hash.inspect }
        resource.provider = provider
      end
    end
  end

  def create
    template = self.class.instance_variable_get('@template')
    prefix = @resource[:prefix]

    debug 'Creating the resource %{resource}.' % { resource: @resource.to_hash.inspect }

    cmds = []
    cmds << 'configure terminal'

    distance = @resource[:distance] unless @resource[:distance] == :absent
    nexthop = @resource[:nexthop] unless @resource[:nexthop] == :absent
    option = @resource[:option] unless @resource[:option] == :absent

    cmds << ERB.new(template).result(binding)

    cmds << 'end'
    cmds << 'write memory'
    vtysh(cmds.reduce([]) { |commands, command| commands << '-c' << command })

    @property_hash = @resource.to_hash
  end

  def destroy
    template = self.class.instance_variable_get('@template')
    prefix = @property_hash[:prefix]

    debug 'Destroying the resource %{resource}.' % { resource: @property_hash.inspect }

    cmds = []
    cmds << 'configure terminal'

    distance = @property_hash[:distance] unless @property_hash[:distance] == :absent
    nexthop = @property_hash[:nexthop] unless @property_hash[:nexthop] == :absent
    option = @property_hash[:option] unless @property_hash[:option] == :absent

    cmds << 'no %{command}' % { command: ERB.new(template).result(binding) }

    cmds << 'end'
    cmds << 'write memory'
    vtysh(cmds.reduce([]) { |commands, command| commands << '-c' << command })

    @property_hash.clear
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def distance=(_value)
    create
  end

  def option=(_value)
    destroy
    create
  end

  def name
    "#{prefix} #{nexthop}"
  end
end
