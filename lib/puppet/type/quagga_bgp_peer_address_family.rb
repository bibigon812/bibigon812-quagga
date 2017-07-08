Puppet::Type.newtype(:quagga_bgp_peer_address_family) do
  @doc = %q{
    This type provides capabilities to manage Quagga bgp address family parameters.

      Examples:

        quagga_bgp_peer_address_family { '192.168.0.2 ipv4_unicast':
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
    desc 'Contains a bgp peer name and an address family.'

    newvalues(/\A[\d\.]+\sipv4_(unicast|multicast)\Z/)
    newvalues(/\A[\h:]+\sipv6_unicast\Z/)
    newvalues(/\A\w+\sipv4_(unicast|multicast)\Z/)
    newvalues(/\A\w+\sipv6_unicast\Z/)
  end

  newproperty(:peer_group) do
    desc 'Member of the peer-group.'

    defaultto do
      resource[:name] =~ /(\.|:)/ ? :false : :true
    end

    newvalues(:false, :true)
    newvalues(/\A[[:alpha:]]\w+\Z/)
  end

  newproperty(:activate, :boolean => true) do
    desc 'Enable the Address Family for this Neighbor.'

    defaultto :false

    newvalues(:false, :true)
  end

  newproperty(:allow_as_in) do
    desc 'Accept as-path with my AS present in it.'
    defaultto(:absent)

    validate do |value|
      unless value == :absent
        fail "Invalid value \"#{value}\", valid value is an Integer" unless value.is_a?(Integer)
        fail "Invalid value \"#{value}\", valid values are 1-4294967295" unless value >= 1 and value <= 4294967295
      end
    end
  end

  newproperty(:default_originate, :boolean => true) do
    desc 'Originate default route to this neighbor.'
    defaultto(:false)
    newvalues(:false, :true)

    validate do |value|
      super(value)
      unless [:true, :false].include?(resource[:peer_group])
        fail 'Invalid command for a peer-group member.' if value == :true
      end
    end
  end

  newproperty(:next_hop_self, :boolean => true) do
    desc 'Disable the next hop calculation for this neighbor.'
    defaultto(:false)
    newvalues(:false, :true)
  end

  newproperty(:prefix_list_in) do
    desc 'Filter updates from this neighbor.'
    defaultto(:absent)
    newvalues(:absent)
    newvalues(/\A[[:alpha:]][\w-]+\Z/)
  end

  newproperty(:prefix_list_out) do
    desc 'Filter updates to this neighbor.'
    defaultto(:absent)
    newvalues(:absent)
    newvalues(/\A[[:alpha:]][\w-]+\Z/)

    validate do |value|
      super(value)
      unless [:true, :false].include?(resource[:peer_group])
        fail 'Invalid command for a peer-group member.' unless value == :absent
      end
    end
  end

  newproperty(:route_map_export) do
    desc 'Apply map to routes coming from a Route-Server client.'
    defaultto(:absent)
    newvalues(:absent)
    newvalues(/\A[[:alpha:]][\w-]+\Z/)
  end

  newproperty(:route_map_import) do
    desc 'Apply map to routes going into a Route-Server client\'s table.'
    defaultto(:absent)
    newvalues(:absent)
    newvalues(/\A[[:alpha:]][\w-]+\Z/)

    validate do |value|
      super(value)
      unless [:true, :false].include?(resource[:peer_group])
        fail 'Invalid command for a peer-group member.' unless value == :absent
      end
    end
  end

  newproperty(:route_map_in) do
    desc 'Apply map to incoming routes.'
    defaultto(:absent)
    newvalues(:absent)
    newvalues(/\A[[:alpha:]][\w-]+\Z/)
  end

  newproperty(:route_map_out) do
    desc 'Apply map to outbound routes.'
    defaultto(:absent)
    newvalues(:absent)
    newvalues(/\A[[:alpha:]][\w-]+\Z/)

    validate do |value|
      super(value)
      unless [:true, :false].include?(resource[:peer_group])
        fail 'Invalid command for a peer-group member.' unless value == :absent
      end
    end
  end

  newproperty(:route_reflector_client, :boolean => true) do
    desc 'Configure a neighbor as Route Reflector client.'
    defaultto(:false)
    newvalues(:false, :true)

    validate do |value|
      super(value)
      unless [:true, :false].include?(resource[:peer_group])
        fail 'Invalid command for a peer-group member.' if value == :true
      end
    end
  end

  newproperty(:route_server_client, :boolean => true) do
    desc 'Configure a neighbor as Route Server client.'
    defaultto(:false)
    newvalues(:false, :true)

    validate do |value|
      super(value)
      unless [:true, :false].include?(resource[:peer_group])
        fail 'Invalid command for a peer-group member.' if value == :true
      end
    end
  end

  autorequire(:quagga_bgp_router) do
    %w{bgp}
  end

  autorequire(:quagga_bgp_peer) do
    [ self[:name].split(/\s/).first ]
  end

  autorequire(:quagga_bgp_peer_address_family) do
    if [:false, :true].include?(self[:peer_group])
      []
    else
      [ "#{self[:peer_group]} #{self[:name].split(/\s/).last}" ]
    end
  end

  autorequire(:package) do
    %w{quagga}
  end

  autorequire(:service) do
    %w{zebra bgpd}
  end

# TODO:
  # autosubscribe(:quagga_prefix_list) do
  #   as = self[:name].split(/\s/).first
  #   peer_prefix_lists = {}
  #   peer_group_prefix_lists = {}
  #   reqs = []
  #
  #   unless self[:peer_group] == :true
  #     # Collect peer's prefix-lists unless it's a peer-group
  #     [:prefix_list_in, :prefix_list_out].each do |property|
  #       peer_prefix_lists[property] = self[property] unless self[property].nil?
  #     end
  #
  #     unless self[:peer_group] == :false
  #       # Collect peer-group's prefix-lists if peer has parent peer-group
  #       peer_group = self[:peer_group]
  #
  #       catalog.resources.select { |resource| resource.type == :quagga_bgp_peer }
  #           .select { |resource| resource[:name] == "#{as} #{peer_group}" }.each do |resource|
  #         [:prefix_list_in, :prefix_list_out].each do |property|
  #           peer_group_prefix_lists[property] = resource[property] unless resource[property].nil?
  #         end
  #       end
  #     end
  #   end
  #
  #   prefix_lists = catalog.resources.select { |resource| resource.type == :quagga_prefix_list }
  #   peer_group_prefix_lists.merge(peer_prefix_lists).values.uniq.each do |name|
  #     reqs += prefix_lists.select { |resource| resource[:name].start_with? "#{name}:" }
  #   end
  #
  #   reqs
  # end
  #
  # autosubscribe(:quagga_route_map) do
  #   as = self[:name].split(/\s/).first
  #   peer_route_maps = {}
  #   peer_group_route_maps = {}
  #   reqs = []
  #
  #   unless self[:peer_group] == :true
  #     # Collect peer's route-maps unless it's a peer-group
  #     [:route_map_export, :route_map_import, :route_map_in, :route_map_out].each do |property|
  #       peer_route_maps[property] = self[property] unless self[property].nil?
  #     end
  #
  #     unless self[:peer_group] == :false
  #       # Collect peer-group's route-maps if peer has parent peer-group
  #       peer_group = self[:peer_group]
  #
  #       catalog.resources.select { |resource| resource.type == :quagga_bgp_peer }
  #           .select { |resource| resource[:name] == "#{as} #{peer_group}" }.each do |resource|
  #         [:route_map_export, :route_map_import, :route_map_in, :route_map_out].each do |property|
  #           peer_group_route_maps[property] = resource[property] unless resource[property] == :absent
  #         end
  #       end
  #     end
  #   end
  #
  #   route_maps = catalog.resources.select { |resource| resource.type == :quagga_route_map }
  #   peer_group_route_maps.merge(peer_route_maps).values.uniq.each do |name|
  #     reqs += route_maps.select { |resource| resource[:name].start_with? "#{name}:" }
  #   end
  #
  #   reqs
  # end
end
