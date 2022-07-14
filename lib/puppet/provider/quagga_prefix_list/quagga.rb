Puppet::Type.type(:quagga_prefix_list).provide :quagga do
  @doc = ' Manages prefix lists using quagga '

  @resource_properties = [
    :action, :prefix, :ge, :le, :proto
  ]

  @resource_template = '<%= proto %> prefix-list <%= name %> seq <%= sequence %> <%= action %> <%= prefix %><% unless ge.nil? %> ge <%= ge %><% end %><% unless le.nil? %> le <%= le %><% end %>'

  commands vtysh: 'vtysh'

  mk_resource_methods

  def self.instances
    providers = []
    found_prefix_list = false

    config = vtysh('-c', 'show running-config')
    config.split(%r{\n}).map do |line|
      next if %r{\A!\Z}.match?(line)

      if line =~ %r{^(ip|ipv6)\sprefix-list\s([\w-]+)\sseq\s(\d+)\s(permit|deny)\s(\S+)(?:\sge\s(\d+))?(?:\sle\s(\d+))?$}

        hash = {
          action: Regexp.last_match(4).to_sym,
            ensure: :present,
            ge: Regexp.last_match(6).nil? ? :absent : Integer(Regexp.last_match(6)),
            le: Regexp.last_match(7).nil? ? :absent : Integer(Regexp.last_match(7)),
            name: "#{Regexp.last_match(2)} #{Regexp.last_match(3)}",
            prefix: Regexp.last_match(5),
            proto: Regexp.last_match(1).to_sym,
            provider: name,
        }

        debug 'Instantiated the prefix-list %{name}.' % { name: hash[:name] }

        providers << new(hash)

        found_prefix_list = true

      elsif line =~ (%r{\A\w}) && found_prefix_list
        break
      end
    end

    providers
  end

  def self.prefetch(resources)
    providers = instances
    resources.each_key do |name|
      if (provider = providers.find { |providerx| providerx.name == name })
        resources[name].provider = provider
      end
    end
  end

  def create
    template = self.class.instance_variable_get('@resource_template')

    name, sequence = @resource[:name].split(%r{\s})

    debug 'Creating the prefix-list %{name}.' % { name: @resource[:name] }

    cmds = []
    cmds << 'configure terminal'

    proto = @resource[:proto]
    action = @resource[:action]
    prefix = @resource[:prefix]
    ge = @resource[:ge] unless @resource[:ge] == :absent
    le = @resource[:le] unless @resource[:le] == :absent

    cmds << ERB.new(template).result(binding)

    cmds << 'end'
    cmds << 'write memory'
    vtysh(cmds.reduce([]) { |commands, command| commands << '-c' << command })

    @property_hash = @resource.to_hash
  end

  def destroy
    template = self.class.instance_variable_get('@resource_template')
    name, sequence = @property_hash[:name].split(%r{\s})

    debug 'Destroying the prefix-list %{name}.' % { name: @property_hash[:name] }

    cmds = []
    cmds << 'configure terminal'

    proto = @property_hash[:proto]
    action = @property_hash[:action]
    prefix = @property_hash[:prefix]
    ge = @property_hash[:ge] unless @property_hash[:ge] == :absent
    le = @property_hash[:le] unless @property_hash[:le] == :absent

    cmds << 'no %{command}' % { command: ERB.new(template).result(binding) }

    cmds << 'end'
    cmds << 'write memory'
    vtysh(cmds.reduce([]) { |commands, command| commands << '-c' << command })

    @property_hash.clear
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def flush
    return unless @property_hash[:ensure] == :present

    name, _sequence = @property_hash[:name].split(%r{\s})

    debug 'Flushing the prefix-list %{name}.' % { name => @property_hash[name] }

    create
  end
end
