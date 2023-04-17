Puppet::Type.newtype(:quagga_bgp_peer) do
  @doc = "
    This type provides the capability to manage bgp neighbor within puppet.

      Examples:

        quagga_bgp_peer { '192.168.1.1':
            ensure     => present,
            peer_group => 'internal_peers',
            passwword  => 'QWRF$345!#@$',
        }

        quagga_bgp_peer { 'internal_peers':
            ensure        => present,
            local_as      => 65000,
            peer_group    => true,
            remote_as     => 65000,
            ebgp_multihop => 2,
        }
  "

  ensurable

  newparam(:name) do
    desc 'The neighbor IP address or a peer-group name.'

    newvalues(%r{\A(\d{,2}|1\d{2}|2[0-4]\d|25[0-5])\.(\d{,2}|1\d{2}|2[0-4]\d|25[0-5])\.(\d{,2}|1\d{2}|2[0-4]\d|25[0-5])\.(\d{,2}|1\d{2}|2[0-4]\d|25[0-5])\Z})
    newvalues(%r{\A[\h:]+\Z})
    newvalues(%r{\A\w+\Z})
  end

  newproperty(:local_as) do
    desc 'Specify a local-as number.'

    defaultto(:absent)

    validate do |value|
      unless value == :absent
        raise "Invalid value \"#{value}\", valid value is an Integer" unless value.is_a?(Integer)
        raise "Invalid value \"#{value}\", valid values are 1-4294967295" unless (value >= 1) && (value <= 4_294_967_295)
      end
    end
  end

  newproperty(:passive, boolean: true) do
    desc 'Don\'t send open messages to this neighbor.'

    defaultto(:false)
    newvalues(:false, :true)
  end

  newproperty(:peer_group) do
    desc 'Member of the peer-group.'

    defaultto { %r{\.|:}.match?(resource[:name]) ? :false : :true }

    newvalues(:false, :true)
    newvalues(%r{\A[[:alpha:]]\w+\Z})
  end

  newproperty(:remote_as) do
    desc 'Specify a BGP neighbor AS.'

    defaultto(:absent)

    validate do |value|
      unless value == :absent
        raise "Invalid value \"#{value}\", valid value is an Integer" unless value.is_a?(Integer)
        raise "Invalid value \"#{value}\", valid values are 1-4294967295" unless (value >= 1) && (value <= 4_294_967_295)
      end
    end
  end

  newproperty(:shutdown, boolean: true) do
    desc 'Administratively shut down this neighbor.'
    defaultto(:false)
    newvalues(:false, :true)
  end

  newproperty(:update_source) do
    desc 'Source of routing updates.'

    block = %r{\d{,2}|1\d{2}|2[0-4]\d|25[0-5]}
    interface = %r{[[:alpha:]]\w+(\.\d+(:\d+)?)?}

    defaultto(:absent)
    newvalues(:absent)
    newvalues(%r{\A#{block}\.#{block}\.#{block}\.#{block}\Z})
    newvalues(%r{\A\h+:[\h:]+\Z})
    newvalues(%r{\A#{interface}\Z})
  end

  newproperty(:password) do
    desc 'Set a password'

    defaultto(:absent)
  end

  newproperty(:ebgp_multihop) do
    desc 'Number of allowed hops to remote BGP peer'

    validate do |value|
      unless value == :absent
        raise "Invalid value \"#{value}\", valid value is an Integer" unless value.is_a?(Integer)
        raise "Invalid value \"#{value}\", valid values are 1-4294967295" unless (value >= 1) && (value <= 255)
      end
    end

    defaultto(:absent)
  end

  autorequire(:quagga_bgp_router) do
    ['bgp']
  end

  autorequire(:quagga_bgp_peer) do
    if [:false, :true].include?(self[:peer_group])
      []
    else
      [self[:peer_group]]
    end
  end

  autorequire(:package) do
    ['quagga']
  end

  autorequire(:service) do
    ['zebra', 'bgpd']
  end
end
