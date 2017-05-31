Puppet::Type.type(:bgp_network).provide :quagga do
  @doc = %q{ Manages bgp neighbors using quagga }

  commands :vtysh => 'vtysh'

  mk_resource_methods

  def self.instances
    debug '[instances]'
    found_config = false
    networks = []
    as = ''
    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|
      # Find 'router bgp ...' and store the AS number
      if line =~ /\Arouter\sbgp\s(\d+)\Z/
        as = $1
        found_config = true
      elsif line =~ /\A\snetwork\s([\h\.\/:]+)\Z/
        hash = {}
        network = $1
        hash[:name] = "#{as} #{network}"
        hash[:provider] = self.name
        hash[:ensure] = :present
        debug "bgp_network: #{hash}"
        networks << new(hash)
      elsif line =~ /^\w/ and found_config
        break
      end
    end
    networks
  end

  def self.prefetch(resources)
    providers = instances
    found_providers = []
    resources.keys.each do |name|
      if provider = providers.find{ |provider| provider.name == name }
        resources[name].provider = provider
        found_providers << provider
      end
    end
    (providers - found_providers).each do |provider|
      provider.destroy
    end
  end

  def create
    debug '[create]'

    cmds = []
    as, network = @resource[:name].split(/\s+/)

    cmds << 'configure terminal'
    cmds << "router bgp #{as}"

    if network.include?(':')
      cmds << "ipv6 bgp network #{network}"
    else
      cmds << "network #{network}"
    end

    cmds << 'end'
    cmds << 'write memory'

    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })

    @property_hash[:name] = @resource[:name]
    @property_hash[:ensure] = :present
  end

  def destroy
    debug '[destroy]'

    cmds = []
    as, network = @property_hash[:name].split(/\s+/)

    cmds << 'configure terminal'
    cmds << "router bgp #{as}"

    if network.include?(':')
      cmds << "no ipv6 bgp network #{network}"
    else
      cmds << "no network #{network}"
    end

    cmds << 'end'
    cmds << 'write memory'

    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })

    @property_hash.clear
  end

  def exists?
    @property_hash[:ensure] == :present
  end
end
