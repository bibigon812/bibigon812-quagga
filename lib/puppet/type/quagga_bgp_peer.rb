Puppet::Type.newtype(:quagga_bgp_peer) do
  @doc = %q{
    This type provides the capability to manage bgp neighbor within puppet.

      Examples:

        quagga_bgp_peer { '192.168.1.1':
            ensure     => present,
            peer_group => 'internal_peers',
        }

        quagga_bgp_peer { 'internal_peers':
            ensure     => present,
            local_as   => 65000,
            peer_group => true,
            remote_as  => 65000,
        }
  }

  ensurable

  newparam(:name) do
    desc 'The neighbor IP address or a peer-group name.'

    newvalues(/\A(\d{,2}|1\d{2}|2[0-4]\d|25[0-5])\.(\d{,2}|1\d{2}|2[0-4]\d|25[0-5])\.(\d{,2}|1\d{2}|2[0-4]\d|25[0-5])\.(\d{,2}|1\d{2}|2[0-4]\d|25[0-5])\Z/)
    newvalues(/\A[\h:]+\Z/)
    newvalues(/\A\w+\Z/)
  end

  newproperty(:local_as) do
    desc 'Specify a local-as number.'

    defaultto(:absent)

    validate do |value|
      unless value == :absent
        fail "Invalid value \"#{value}\", valid value is an Integer" unless value.is_a?(Integer)
        fail "Invalid value \"#{value}\", valid values are 1-4294967295" unless value >= 1 and value <= 4294967295
      end
    end
  end

  newproperty(:passive, :boolean => true) do
    desc 'Don\'t send open messages to this neighbor.'

    defaultto(:false)
    newvalues(:false, :true)
  end

  newproperty(:peer_group) do
    desc 'Member of the peer-group.'

    defaultto { resource[:name] =~ /\.|:/ ? :false : :true }

    newvalues(:false, :true)
    newvalues(/\A[[:alpha:]]\w+\Z/)
  end

  newproperty(:remote_as) do
    desc 'Specify a BGP neighbor AS.'

    defaultto(:absent)

    validate do |value|
      unless value == :absent
        fail "Invalid value \"#{value}\", valid value is an Integer" unless value.is_a?(Integer)
        fail "Invalid value \"#{value}\", valid values are 1-4294967295" unless value >= 1 and value <= 4294967295
      end
    end
  end

  newproperty(:shutdown, :boolean => true) do
    desc 'Administratively shut down this neighbor.'
    defaultto(:false)
    newvalues(:false, :true)
  end

  newproperty(:update_source) do
    desc 'Source of routing updates.'

    block = /\d{,2}|1\d{2}|2[0-4]\d|25[0-5]/
    interface = /[[:alpha:]]\w+(\.\d+(:\d+)?)?/

    defaultto(:absent)
    newvalues(:absent)
    newvalues(/\A#{block}\.#{block}\.#{block}\.#{block}\Z/)
    newvalues(/\A\h+:[\h:]+\Z/)
    newvalues(/\A#{interface}\Z/)
  end

  autorequire(:quagga_bgp_router) do
    %w{bgp}
  end

  autorequire(:quagga_bgp_peer) do
    if [:false, :true].include?(self[:peer_group])
      []
    else
      [self[:peer_group]]
    end
  end

  autorequire(:package) do
    %w{quagga}
  end

  autorequire(:service) do
    %w{zebra bgpd}
  end
end
