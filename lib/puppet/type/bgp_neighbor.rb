Puppet::Type.newtype(:bgp_neighbor) do
  @doc = %q{
    This type provides the capability to manage bgp neighbor within
    puppet.

    Examples:

      bgp_neighbor { '65000:192.168.1.1':
        ensure                 => 'present',
        activate               => 'enabled',
        peer_group             => 'internal_peers',
        route_reflector_client => 'enabled',
      }

      bgp_neighbor { '65000:internal_peers':
        ensure            => 'present',
        allow_as_in       => 1,
        default_originate => 'disabled',
        local_as          => 65000,
        peer_group        => 'enabled',
        prefix_list_in    => 'PREFIX_LIST_IN',
        prefix_list_out   => 'PREFIX_LIST_OUT',
        remote_as         => 65000,
        route_map_in      => 'ROUTE_MAP_IN',
        route_map_out     => 'ROUTE_MAP_OUT',
      }
  }

  ensurable

  newparam(:name) do
    desc %q{ It's consists of a AS number and a neighbor IP address or a peer-group name }

    block = /\d{,2}|1\d{2}|2[0-4]\d|25[0-5]/
    re = /\A\d+:#{block}\.#{block}\.#{block}\.#{block}\Z/

    newvalues(re)
    newvalues(/\A\d+:[\h:]\Z/)
    newvalues(/\A\d+:\w+\Z/)
  end

  newproperty(:activate) do
    desc %q{ Enable the Address Family for this Neighbor }
    defaultto(:disabled)
    newvalues(:disabled, :enabled, :false, :true)

    munge do |value|
      case value
        when :false, 'false', false, 'disabled'
          :disabled
        when :true, 'true', true, 'enabled'
          :enabled
        else
          value
      end
    end
  end

  newproperty(:allow_as_in) do
    desc %q{ Accept as-path with my AS present in it }
    newvalues(/\A(10|[1-9])\Z/)

    munge do |value|
      value.to_i
    end
  end

  newproperty(:default_originate) do
    desc %q{ Originate default route to this neighbor }
    defaultto(:disabled)
    newvalues(:disabled, :enabled, :false, :true)

    munge do |value|
      case value
        when :false, 'false', false, 'disabled'
          :disabled
        when :true, 'true', true, 'enabled'
          :enabled
        else
          value
      end
    end
  end

  newproperty(:local_as) do
    desc %q{ Specify a local-as number }
    newvalues(/\A\d+\Z/)

    validate do |value|
      if value.to_i < 1
        raise(ArgumentError, "Invalid value \"#{value}\", valid values are 1-4294967295")
      end
    end

    munge do |value|
      value.to_i
    end
  end

  newproperty(:next_hop_self) do
    desc %q{ Disable the next hop calculation for this neighbor }
    defaultto(:disabled)
    newvalues(:disabled, :enabled, :false, :true)

    munge do |value|
      case value
        when :false, 'false', false, 'disabled'
          :disabled
        when :true, 'true', true, 'enabled'
          :enabled
        else
          value
      end
    end
  end

  newproperty(:passive) do
    desc %q{ Don't send open messages to this neighbor }
    defaultto(:disabled)
    newvalues(:disabled, :enabled, :false, :true)

    munge do |value|
      case value
        when :false, 'false', false, 'disabled'
          :disabled
        when :true, 'true', true, 'enabled'
          :enabled
        else
          value
      end
    end
  end

  newproperty(:peer_group) do
    desc %q{ Member of the peer-group. }
    defaultto(:disabled)
    newvalues(:disabled, :enabled, :false, :true)
    newvalues(/\A[[:alpha:]]\w+\Z/)
    munge do |value|
      case value
        when :true, 'true', true, 'enabled'
          :enabled
        when :false, 'false', false, 'disabled'
          :disabled
        when String
          value.to_sym
        else
          value
      end
    end
  end

  newproperty(:prefix_list_in) do
    desc %q{ Filter updates from this neighbor }
    newvalues(/\A[[:alpha:]][\w-]+\Z/)
  end

  newproperty(:prefix_list_out) do
    desc %q{ Filter updates to this neighbor }
    newvalues(/\A[[:alpha:]][\w-]+\Z/)
  end

  newproperty(:remote_as) do
    desc %q{ Specify a BGP neighbor as }
    newvalues(/\A\d+\Z/)

    validate do |value|
      if value.to_i < 1
        raise(ArgumentError, "Invalid value \"#{value}\", valid values are 1-4294967295")
      end
    end

    munge do |value|
      value.to_i
    end
  end

  newproperty(:route_map_export) do
    desc %q{ Apply map to routes coming from a Route-Server client }
    newvalues(/\A[[:alpha:]][\w-]+\Z/)
  end

  newproperty(:route_map_import) do
    desc %q{ Apply map to routes going into a Route-Server client's table }
    newvalues(/\A[[:alpha:]][\w-]+\Z/)
  end

  newproperty(:route_map_in) do
    desc %q{ Apply map to incoming routes }
    newvalues(/\A[[:alpha:]][\w-]+\Z/)
  end

  newproperty(:route_map_out) do
    desc %q{ Apply map to outbound routes }
    newvalues(/\A[[:alpha:]][\w-]+\Z/)
  end

  newproperty(:route_reflector_client) do
    desc %q{ Configure a neighbor as Route Reflector client }
    defaultto(:disabled)
    newvalues(:disabled, :enabled, :false, :true)

    munge do |value|
      case value
        when :false, 'false', false, 'disabled'
          :disabled
        when :true, 'true', true, 'enabled'
          :enabled
        else
          value
      end
    end
  end

  newproperty(:route_server_client) do
    desc %q{ Configure a neighbor as Route Server client }
    defaultto(:disabled)
    newvalues(:disabled, :enabled, :false, :true)

    munge do |value|
      case value
        when :false, 'false', false, 'disabled'
          :disabled
        when :true, 'true', true, 'enabled'
          :enabled
        else
          value
      end
    end
  end

  newproperty(:shutdown) do
    desc %q{ Administratively shut down this neighbor }
    defaultto(:disabled)
    newvalues(:disabled, :enabled, :false, :true)

    munge do |value|
      case value
        when :false, 'false', false, 'disabled'
          :disabled
        when :true, 'true', true, 'enabled'
          :enabled
        else
          value
      end
    end
  end

  autorequire(:bgp) do
    reqs = []
    as = value(:name).split(/:/).first

    unless as.nil?
      reqs << as
    end

    reqs
  end

  autorequire(:bgp_neighbor) do
    reqs = []
    peer_group = value(:peer_group)
    unless peer_group.nil? || peer_group == :enabled
      reqs << peer_group
    end

    reqs
  end

  autorequire(:package) do
    case value(:provider)
      when :quagga
        %w{quagga}
      else
        []
    end
  end

  autorequire(:service) do
    case value(:provider)
      when :quagga
        %w{zebra bgpd}
      else
        []
    end
  end
end