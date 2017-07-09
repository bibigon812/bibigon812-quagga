Puppet::Type.type(:quagga_prefix_list).provide :quagga do
  @doc = %q{ Manages prefix lists using quagga }

  @resource_properties = [
      :action, :prefix, :ge, :le, :proto,
  ]

  @resource_template = '<%= proto %> prefix-list <%= name %> seq <%= sequence %> <%= action %> <%= prefix %><% unless ge.nil? %> ge <%= ge %><% end %><% unless le.nil? %> le <%= le %><% end %>'

  commands :vtysh => 'vtysh'

  mk_resource_methods

  def self.instances
    providers = []
    found_prefix_list = false

    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|

      next if line =~ /\A!\Z/

      if line =~ /^(ip|ipv6)\sprefix-list\s([\w-]+)\sseq\s(\d+)\s(permit|deny)\s([\d\.\/:]+|any)(\s(ge|le)\s(\d+)(\s(ge|le)\s(\d+))?)?$/

        hash = {
            :action   => $4.to_sym,
            :ensure   => :present,
            :ge       => $7.nil? ? :absent : Integer($8),
            :le       => $11.nil? ? :absent : Integer($11),
            :name     => "#{$2} #{$3}",
            :prefix   => $5,
            :proto    => $1.to_sym,
            :provider => self.name,
        }

        debug 'Instantiated the prefix-list %{name}.' % { :name => hash[:name] }

        providers << new(hash)

        found_prefix_list = true

      elsif line =~ /\A\w/ and found_prefix_list
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

    name, sequence = @resource[:name].split(/\s/)

    debug 'Creating the prefix-list %{name}.' % { :name => @resource[:name] }

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
    vtysh(cmds.reduce([]){ |commands, command| commands << '-c' << command })

    @property_hash[:ensure] = :present
  end

  def destroy
    template = self.class.instance_variable_get('@resource_template')
    name, sequence = @property_hash[:name].split(/\s/)

    debug 'Destroying the prefix-list %{name}.' % { :name => @property_hash[:name] }

    cmds = []
    cmds << 'configure terminal'

    proto = @property_hash[:proto]
    action = @property_hash[:action]
    prefix = @property_hash[:prefix]
    ge = @property_hash[:ge] unless @property_hash[:ge] == :absent
    le = @property_hash[:le] unless @property_hash[:le] == :absent

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

    name, sequence = @property_hash[:name].split(/\s/)

    debug 'Flushing the prefix-list %{name}.' % { :name => @property_hash[:name] }

    create
  end
end
