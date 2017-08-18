Puppet::Type.type(:quagga_static_route).provide :quagga do
  @doc = %q{ Manages static routes using zebra }

  @resource_properties = [
      :gateway, :interface, :distance,
  ]

  @resource_template = 'ip route <%= name %> <% if not gateway.nil? %><%= gateway %><% elsif not interface.nil? %><%= interface %><% end %><% unless distance.nil? %> <%= distance %><% end %>'

  commands :vtysh => 'vtysh'

  mk_resource_methods

  def self.instances
    providers = []
    found_route = false

    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|

      if line =~ /\Aip\sroute\s(\d+{1,3}\.\d+{1,3}\.\d+{1,3}\.\d{1,3}\/\d{1,2})\s(\d+{1,3}\.\d+{1,3}\.\d+{1,3}\.\d{1,3}|\w+)\s?(\d{1,3})?\Z/

        name = $1
        if $2 =~ /\d+{1,3}\.\d+{1,3}\.\d+{1,3}\.\d{1,3}/
          gateway_address = $2
          interface_name  = :absent
        else
          gateway_address = :absent
          interface_name  = $2
        end

        distance = $3.nil? ? :absent : Integer($3)

        hash = {
            :name      => name,
            :ensure    => :present,
            :gateway   => gateway_address,
            :interface => interface_name,
            :distance  => distance,
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
      if provider = providers.find{ |provider| provider.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
    template = self.class.instance_variable_get('@resource_template')
    name = @resource[:name]

    debug 'Creating route to %{name}.' % { :name => @resource[:name] }

    cmds = []
    cmds << 'configure terminal'

    gateway = @resource[:gateway] unless @resource[:gateway] == :absent
    interface = @resource[:interface] unless @resource[:interface] == :absent
    distance = @resource[:distance] unless @resource[:distance] == :absent

    cmds << ERB.new(template).result(binding)

    cmds << 'end'
    cmds << 'write memory'
    vtysh(cmds.reduce([]){ |commands, command| commands << '-c' << command })

    @property_hash = @resource.to_hash
  end

  def destroy
    template = self.class.instance_variable_get('@resource_template')
    name = @property_hash[:name]

    debug 'Destroying the prefix-list %{name}.' % { :name => @property_hash[:name] }

    cmds = []
    cmds << 'configure terminal'

    gateway = @property_hash[:gateway] unless @property_hash[:gateway] == :absent
    interface = @property_hash[:interface] unless @property_hash[:interface] == :absent
    distance = @property_hash[:distance] unless @property_hash[:distance] == :absent

    cmds << 'no %{command}' % { :command => ERB.new(template).result(binding) }

    cmds << 'end'
    cmds << 'write memory'
    vtysh(cmds.reduce([]){ |commands, command| commands << '-c' << command })

    @property_hash.clear
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def flush
    return unless @property_hash[:ensure] == :present

    name = @property_hash[:name]

    debug 'Flushing the route to %{name}.' % { :name => @property_hash[:name] }

    create
  end
end
