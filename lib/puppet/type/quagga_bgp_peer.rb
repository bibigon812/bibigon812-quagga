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

  feature :refreshable, 'The provider can clean a bgp session.', :methods => [:clear]

  ensurable

  newparam(:name) do
    desc 'It\'s consists of a AS number and a neighbor IP address or a peer-group name.'

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
    desc 'Specify a BGP neighbor as.'

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
  #         .select { |resource| resource[:name] == "#{as} #{peer_group}" }.each do |resource|
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

  def refresh
    if self[:shutdown] == :false
      provider.clear
    else
      debug 'Skipping clear; the bgp session shutdown'
    end
  end
end
