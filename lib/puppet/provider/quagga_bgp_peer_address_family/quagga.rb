Puppet::Type.type(:quagga_bgp_peer_address_family).provide :quagga do
  @doc = 'Manages the address family of bgp peers using quagga.'

  confine :osfamily => :redhat

  commands vtysh: 'vtysh'

  def self.instaneces
    # TODO
    providers = []
    hash = {}
    found_router = false
    address_family = 'ipv4 unicast'
    as = ''

    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|
      # Skip comments
      next if line =~ /\A!/

      # Found the router bgp
      if line =~ /\Arouter\sbgp\s(\d+)\Z/
        as = $1
        found_router = true

      # Found the address family
      elsif found_router and line =~ /\A\saddress-family\s(ipv4|ipv6)(?:\s(multicast))?\Z/
        proto = $1
        type = $2
        address_family = type.nil? ? proto : "#{proto} #{type}"

      # Exit
      elsif found_router and line =~ /\A\w/
        break

      end
    end

    providers
  end

  def self.prefetch(resources)
    providers = instances
    resources.keys.each do |name|
      if provider = providers.find{ |pkg| pkg.name == name }
        resources[name].provider = provider
      end
    end
  end

  # TODO
end

