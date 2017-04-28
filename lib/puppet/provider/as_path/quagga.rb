Puppet::Type.type(:as_path).provide :quagga do
  @doc = %q{ Manages as-path access-list using quagga }

  commands :vtysh => 'vtysh'

  mk_resource_methods

  def self.instances
    debug '[instances]'

    as_paths = []

    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|
      if line =~ /\Aip\sas-path\saccess-list\s([\w]+)\s(permit|deny)\s(.+)\Z/
        name = $1
        action = $2
        regex = $3
        hash = {}
        hash[:ensure] = :present
        hash[:provider] = self.name
        hash[:name] = "#{name}:#{action}:#{regex}"
        as_paths << new(hash)
      end
    end
    as_paths
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
    (providers - found_providers).each do |provider|
      provider.destroy
    end
  end

  def create
    name, action, regex = @resource[:name].split(/:/)

    @property_hash[:ensure] = :present
    cmds = []
    cmds << 'configure terminal'
    cmds << "ip as-path access-list #{name} #{action} #{regex}"
    cmds << 'end'
    cmds << 'write memory'
    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })
  end

  def destroy
    name, action, regex = @property_hash[:name].split(/:/)

    @property_hash[:ensure] = :absent
    cmds = []
    cmds << 'configure terminal'
    cmds << "no ip as-path access-list #{name} #{action} #{regex}"
    cmds << 'end'
    cmds << 'write memory'
    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })
  end

  def exists?
    @property_hash[:ensure] == :present
  end
end