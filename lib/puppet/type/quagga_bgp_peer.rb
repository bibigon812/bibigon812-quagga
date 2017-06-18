Puppet::Type.newtype(:quagga_bgp_peer) do
  @doc = %q{
    This type provides the capability to manage bgp neighbor within puppet.

      Examples:

        bgp_neighbor { '65000 192.168.1.1':
            ensure                 => present,
            activate               => true,
            peer_group             => 'internal_peers',
            route_reflector_client => true,
        }

        bgp_neighbor { '65000 internal_peers':
            ensure            => present,
            allow_as_in       => 1,
            default_originate => false,
            local_as          => 65000,
            peer_group        => true,
            prefix_list_in    => 'PREFIX_LIST_IN',
            prefix_list_out   => 'PREFIX_LIST_OUT',
            remote_as         => 65000,
            route_map_in      => 'ROUTE_MAP_IN',
            route_map_out     => 'ROUTE_MAP_OUT',
        }
  }

  ensurable

  newparam(:name) do
    desc %q{ It's consists of a AS number and a neighbor IP address or a peer-group name. }

    newvalues(/\A\d+\s+(\d{,2}|1\d{2}|2[0-4]\d|25[0-5])\.(\d{,2}|1\d{2}|2[0-4]\d|25[0-5])\.(\d{,2}|1\d{2}|2[0-4]\d|25[0-5])\.(\d{,2}|1\d{2}|2[0-4]\d|25[0-5])\Z/)
    newvalues(/\A\d+\s+[\h:]\Z/)
    newvalues(/\A\d+\s+\w+\Z/)

    munge do |value|
      value.gsub(/\s+/, ' ')
    end
  end

  newproperty(:activate, :boolean => true) do
    desc %q{ Enable the Address Family for this Neighbor. Default to `enabled`. }

    newvalues(:false, :true)
    defaultto(:true)
  end

  newproperty(:allow_as_in) do
    desc %q{ Accept as-path with my AS present in it. }
    newvalues(/\A(10|[1-9])\Z/)

    munge do |value|
      value.to_i
    end
  end

  newproperty(:default_originate, :boolean => true) do
    desc %q{ Originate default route to this neighbor. Default to `disabled`. }

    newvalues(:false, :true)
    defaultto(:false)
  end

  newproperty(:local_as) do
    desc %q{ Specify a local-as number. }
    newvalues(/\A\d+\Z/)

    validate do |value|
      raise(ArgumentError, "Invalid value \"#{value}\", valid values are 1-4294967295") unless value.to_i > 0
    end

    munge do |value|
      value.to_i
    end
  end

  newproperty(:next_hop_self, :boolean => true) do
    desc %q{ Disable the next hop calculation for this neighbor. Default to `disabled`. }

    newvalues(:false, :true)
    defaultto(:false)
  end

  newproperty(:passive, :boolean => true) do
    desc %q{ Don't send open messages to this neighbor. Default to `disabled`. }

    newvalues(:false, :true)
    defaultto(:false)
  end

  newproperty(:peer_group) do
    desc %q{ Member of the peer-group. Default to `disabled`. }

    newvalues(:false, :true)
    defaultto(:false)
    newvalues(/\A[[:alpha:]]\w+\Z/)
  end

  newproperty(:prefix_list_in) do
    desc %q{ Filter updates from this neighbor. }
    newvalues(/\A[[:alpha:]][\w-]+\Z/)
  end

  newproperty(:prefix_list_out) do
    desc %q{ Filter updates to this neighbor. }
    newvalues(/\A[[:alpha:]][\w-]+\Z/)
  end

  newproperty(:remote_as) do
    desc %q{ Specify a BGP neighbor as. }
    newvalues(/\A\d+\Z/)

    validate do |value|
      raise ArgumentError, "Invalid value \"#{value}\", valid values are 1-4294967295" unless value.to_i > 0
    end

    munge do |value|
      value.to_i
    end
  end

  newproperty(:route_map_export) do
    desc %q{ Apply map to routes coming from a Route-Server client. }
    newvalues(/\A[[:alpha:]][\w-]+\Z/)
  end

  newproperty(:route_map_import) do
    desc %q{ Apply map to routes going into a Route-Server client's table. }
    newvalues(/\A[[:alpha:]][\w-]+\Z/)
  end

  newproperty(:route_map_in) do
    desc %q{ Apply map to incoming routes. }
    newvalues(/\A[[:alpha:]][\w-]+\Z/)
  end

  newproperty(:route_map_out) do
    desc %q{ Apply map to outbound routes. }
    newvalues(/\A[[:alpha:]][\w-]+\Z/)
  end

  newproperty(:route_reflector_client, :boolean => true) do
    desc %q{ Configure a neighbor as Route Reflector client. Default to `disabled`. }

    newvalues(:false, :true)
    defaultto(:false)
  end

  newproperty(:route_server_client, :boolean => true) do
    desc %q{ Configure a neighbor as Route Server client. Default to `disabled`. }

    newvalues(:false, :true)
    defaultto(:false)
  end

  newproperty(:shutdown) do
    desc %q{ Administratively shut down this neighbor. Default to `disabled`. }

    newvalues(:false, :true)
    defaultto(:false)
  end

  newproperty(:update_source) do
    desc %q{ Source of routing updates. }

    block = /\d{,2}|1\d{2}|2[0-4]\d|25[0-5]/
    interface = /[[:alpha:]]\w+(\.\d+(:\d+)?)?/
    newvalues(/\A#{block}\.#{block}\.#{block}\.#{block}\Z/)
    newvalues(/\A\h+:[\h:]+\Z/)
    newvalues(/\A#{interface}\Z/)
  end

  autorequire(:quagga_bgp) do
    reqs = []
    as = value(:name).split(/\s+/).first

    unless as.nil?
      reqs << as
    end

    reqs
  end

  autorequire(:quagga_bgp_peer) do
    reqs = []
    peer_group = value(:peer_group)
    unless peer_group.nil? || peer_group == :enabled
      reqs << peer_group
    end

    reqs
  end

  autorequire(:package) do
    %w{quagga}
  end

  autorequire(:service) do
    %w{zebra bgpd}
  end

  def refresh
    provider.reset
  end
end