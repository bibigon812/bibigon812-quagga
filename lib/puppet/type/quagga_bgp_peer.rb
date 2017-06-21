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

  feature :refreshable, 'The provider can execute the clearing bgp session.', methods: [:reset]

  ensurable

  newparam :name do
    desc 'It\'s consists of a AS number and a neighbor IP address or a peer-group name.'

    newvalues /\A\d+\s+(\d{,2}|1\d{2}|2[0-4]\d|25[0-5])\.(\d{,2}|1\d{2}|2[0-4]\d|25[0-5])\.(\d{,2}|1\d{2}|2[0-4]\d|25[0-5])\.(\d{,2}|1\d{2}|2[0-4]\d|25[0-5])\Z/
    newvalues /\A\d+\s+[\h:]\Z/
    newvalues /\A\d+\s+\w+\Z/

    munge do |value|
      value.gsub /\s+/, ' '
    end
  end

  newproperty :activate, :boolean => true do
    desc 'Enable the Address Family for this Neighbor. Default to `enabled`.'

    newvalues :false, :true
    defaultto :true
  end

  newproperty :allow_as_in do
    desc 'Accept as-path with my AS present in it.'

    newvalues /\A(10|[1-9])\Z/
    newvalues :absent
    defaultto :absent

    munge do |value|
      value.to_i unless value == :absent
    end
  end

  newproperty :default_originate, :boolean => true do
    desc 'Originate default route to this neighbor. Default to `false`.'

    newvalues :false, :true
    defaultto :false
  end

  newproperty :local_as do
    desc 'Specify a local-as number.'
    newvalues /\A\d+\Z/
    newvalues :absent
    defaultto :absent

    validate do |value|
      super value

      unless value == :absent or value.to_i > 0
        raise ArgumentError, "Invalid value \"#{value}\", valid values are 1-4294967295"
      end
    end

    munge do |value|
      value.to_i unless value == :absent
    end
  end

  newproperty :next_hop_self, :boolean => true do
    desc 'Disable the next hop calculation for this neighbor. Default to `false`.'

    newvalues :false, :true
    defaultto :false
  end

  newproperty :passive, :boolean => true do
    desc 'Don\'t send open messages to this neighbor. Default to `false`.'

    newvalues :false, :true
    defaultto :false
  end

  newproperty :peer_group do
    desc 'Member of the peer-group. Default to `false`.'

    newvalues :false, :true
    newvalues /\A[[:alpha:]]\w+\Z/
    defaultto :false
  end

  newproperty :prefix_list_in do
    desc 'Filter updates from this neighbor.'

    newvalues /\A[[:alpha:]][\w-]+\Z/
    newvalues :absent
    defaultto :absent
  end

  newproperty :prefix_list_out do
    desc 'Filter updates to this neighbor.'

    newvalues /\A[[:alpha:]][\w-]+\Z/
    newvalues :absent
    defaultto :absent
  end

  newproperty :remote_as do
    desc 'Specify a BGP neighbor as.'

    newvalues /\A\d+\Z/
    newvalues :absent
    defaultto :absent

    validate do |value|
      super value

      unless value == :absent or value.to_i > 0
        raise ArgumentError, "Invalid value \"#{value}\", valid values are 1-4294967295"
      end
    end

    munge do |value|
      value.to_i unless value == :absent
    end
  end

  newproperty :route_map_export do
    desc 'Apply map to routes coming from a Route-Server client.'

    newvalues /\A[[:alpha:]][\w-]+\Z/
    newvalues :absent
    defaultto :absent
  end

  newproperty :route_map_import do
    desc 'Apply map to routes going into a Route-Server client\'s table.'

    newvalues /\A[[:alpha:]][\w-]+\Z/
    newvalues :absent
    defaultto :absent
  end

  newproperty :route_map_in do
    desc 'Apply map to incoming routes.'

    newvalues /\A[[:alpha:]][\w-]+\Z/
    newvalues :absent
    defaultto :absent
  end

  newproperty :route_map_out do
    desc 'Apply map to outbound routes.'

    newvalues /\A[[:alpha:]][\w-]+\Z/
    newvalues :absent
    defaultto :absent
  end

  newproperty :route_reflector_client, :boolean => true do
    desc 'Configure a neighbor as Route Reflector client. Default to `false`.'

    newvalues :false, :true
    defaultto :false
  end

  newproperty :route_server_client, :boolean => true do
    desc 'Configure a neighbor as Route Server client. Default to `false`.'

    newvalues :false, :true
    defaultto :false
  end

  newproperty :shutdown do
    desc %q{ Administratively shut down this neighbor. Default to `false`. }

    newvalues :false, :true
    defaultto :false
  end

  newproperty :update_source do
    desc 'Source of routing updates.'

    block = /\d{,2}|1\d{2}|2[0-4]\d|25[0-5]/
    interface = /[[:alpha:]]\w+(\.\d+(:\d+)?)?/

    newvalues /\A#{block}\.#{block}\.#{block}\.#{block}\Z/
    newvalues /\A\h+:[\h:]+\Z/
    newvalues /\A#{interface}\Z/
    newvalues :absent
    defaultto :absent
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
    unless value(:peer_group).nil? || value(:peer_group) == :enabled
      [value(:peer_group)]
    else
      []
    end
  end

  autorequire :package do
    %w{quagga}
  end

  autorequire :service do
    %w{zebra bgpd}
  end

  autosubscribe :quagga_prefix_list do
    as = value(:name).split(/\s/).first
    peer_prefix_lists = {}
    peer_group_prefix_lists = {}
    reqs = []

    unless value :peer_group == :true
      # Collect peer's prefix-lists unless it's a peer-group
      [:prefix_list_in, :prefix_list_out].each do |property|
        peer_prefix_lists[property] = value property unless value property == :absent
      end

      unless value :peer_group == :false
        # Collect peer-group's prefix-lists if peer has parent peer-group
        peer_group = value :peer_group

        catalog.resources.select { |resource| resource.type == :quagga_bgp_peer }
            .select { |resource| resource[:name] == "#{as} #{peer_group}" }.each do |resource|
          [:prefix_list_in, :prefix_list_out].each do |property|
            peer_group_prefix_lists[property] = resource[property] unless resource[property] == :absent
          end
        end
      end
    end

    prefix_lists = catalog.resources.select { |resource| resource.type == :quagga_prefix_list }
    peer_group_prefix_lists.merge(peer_prefix_lists).values.uniq.each do |name|
      reqs += prefix_lists.select { |resource| resource[:name].start_with? "#{name}:" }
    end

    reqs
  end

  autosubscribe :quagga_route_map do
    as = value(:name).split(/\s/).first
    peer_route_maps = {}
    peer_group_route_maps = {}
    reqs = []

    unless value :peer_group == :true
      # Collect peer's route-maps unless it's a peer-group
      [:route_map_export, :route_map_import, :route_map_in, :route_map_out].each do |property|
        peer_route_maps[property] = value property unless value property == :absent
      end

      unless value :peer_group == :false
        # Collect peer-group's route-maps if peer has parent peer-group
        peer_group = value :peer_group

        catalog.resources.select { |resource| resource.type == :quagga_bgp_peer }
          .select { |resource| resource[:name] == "#{as} #{peer_group}" }.each do |resource|
          [:route_map_export, :route_map_import, :route_map_in, :route_map_out].each do |property|
            peer_group_route_maps[property] = resource[property] unless resource[property] == :absent
          end
        end
      end
    end

    route_maps = catalog.resources.select { |resource| resource.type == :quagga_route_map }
    peer_group_route_maps.merge(peer_route_maps).values.uniq.each do |name|
      reqs += route_maps.select { |resource| resource[:name].start_with? "#{name}:" }
    end

    reqs
  end
end
