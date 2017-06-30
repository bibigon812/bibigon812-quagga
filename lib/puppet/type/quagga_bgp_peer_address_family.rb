Puppet::Type.newtype(:quagga_bgp_peer_address_family) do
  require 'puppet/property/boolean'

  @doc = %q{
    This type provides capabilities to manage Quagga bgp address family parameters.

      Examples:

        quagga_bgp_peer_address_family { '192.168.0.2 ipv4 unicast':
          peer_group             => PEER_GROUP,
          activate               => true,
          allow_as_in            => 1,
          default_originate      => true,
          maximum_prefix         => 500000,
          next_hop_self          => true,
          prefix_list_in         => PREFIX_LIST,
          prefix_list_out        => PREFIX_LIST,
          remove_private_as      => true,
          route_map_export       => ROUTE_MAP,
          route_map_import       => ROUTE_MAP,
          route_map_in           => ROUTE_MAP,
          route_map_out          => ROUTE_MAP,
          route_reflector_client => false,
          route_server_client    => false,
          send_community         => 'both',
          soft_reconfiguration   => 'inbound',
        }
  }

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Contains the AS number, the neighbor IP address or the peer-group name, the address family.'

    newvalues(/\A\d+\s([\d\.]+)ipv4\s(unicast|multicast)\Z/)
    newvalues(/\A\d+\s([\h\.:]+)\sipv6\Z/)
  end

  newproperty(:activate, boolean: true) do
    desc 'Enable the Address Family for this Neighbor.'
    defaultto(:false)
    newvalues(:false, :true)
  end

  newproperty(:allow_as_in) do
    desc 'Accept as-path with my AS present in it.'
    newvalues(/\A(10|[1-9])\Z/)

    munge do |value|
      Integer(value)
    end

    def insync?(is)
      is == should
    end
  end

  newproperty(:default_originate, boolean: true) do
    desc 'Originate default route to this neighbor. Default to `false`.'
    defaultto(:false)
    newvalues(:false, :true)
  end

  newproperty(:next_hop_self, boolean: true) do
    desc 'Disable the next hop calculation for this neighbor. Default to `false`.'
    defaultto(:false)
    newvalues(:false, :true)
  end

  newproperty(:prefix_list_in) do
    desc 'Filter updates from this neighbor.'
    newvalues(/\A[[:alpha:]][\w-]+\Z/)
  end

  newproperty(:prefix_list_out) do
    desc 'Filter updates to this neighbor.'
    newvalues(/\A[[:alpha:]][\w-]+\Z/)
  end

  newproperty(:route_map_export) do
    desc 'Apply map to routes coming from a Route-Server client.'
    newvalues(/\A[[:alpha:]][\w-]+\Z/)
  end

  newproperty(:route_map_import) do
    desc 'Apply map to routes going into a Route-Server client\'s table.'
    newvalues(/\A[[:alpha:]][\w-]+\Z/)
  end

  newproperty(:route_map_in) do
    desc 'Apply map to incoming routes.'
    newvalues(/\A[[:alpha:]][\w-]+\Z/)
  end

  newproperty(:route_map_out) do
    desc 'Apply map to outbound routes.'
    newvalues(/\A[[:alpha:]][\w-]+\Z/)
  end

  newproperty(:route_reflector_client, boolean: true) do
    desc 'Configure a neighbor as Route Reflector client.'
    defaultto(:false)
    newvalues(:false, :true)
  end

  newproperty(:route_server_client, boolean: true) do
    desc 'Configure a neighbor as Route Server client. Default to `false`.'
    defaultto(:false)
    newvalues(:false, :true)
  end
end
