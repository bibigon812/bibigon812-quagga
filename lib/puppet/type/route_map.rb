Puppet::Type.newtype(:route_map) do
  @doc = %q{

This type provides the capability to manage route-map within puppet.

Example:

```puppet
route_map {'TEST_ROUTE_MAP:permit:10':
  ensure   => present,
  match    => [
    'as-path PATH_LIST',
    'community COMMUNITY_LIST',
  ],
  on_match => 'next',
  set      => [
    'local-preference 200',
    'community none',
  ],
}
```

  }

  ensurable

  newparam(:name) do
    desc %q{ Name of the route-map, action and sequence number of rule. }

    newvalues(/\A\w[\w-]+:(deny|permit):\d+\Z/)
  end

  newproperty(:match, :array_matching => :all) do
    desc %q{ Match values from routing table. }

    newvalues(/\Aas-path\s(\w+)\Z/)
    newvalues(/\Acommunity\s(\w+)(\s(exact-match))?\Z/)
    newvalues(/\Aextcommunity\s(\w+)\Z/)
    newvalues(/\Ainterface\s(\w[\w\.:]+)\Z/)
    newvalues(/\Aip\s(address|next-hop|route-source)\s(\d+)\Z/)
    newvalues(/\Aip\s(address|next-hop|route-source)\s(\w[\w-]+)\Z/)
    newvalues(/\Aip\s(address|next-hop|route-source)\sprefix-list\s(\w[\w-]+)\Z/)
    newvalues(/\Aipv6\s(address|next-hop)\s(\w[\w-]+)\Z/)
    newvalues(/\Aipv6\s(address|next-hop)\sprefix-list\s(\w[\w-]+)\Z/)
    newvalues(/\Alocal-preference\s(\d+)\Z/)
    newvalues(/\Ametric\s(\d+)\Z/)
    newvalues(/\Aorigin\s(egp|igp|incomplete)\Z/)
    newvalues(/\Apeer\s(\d+\.\d+\.\d+\.\d+)\Z/)
    newvalues(/\Apeer\s([\d:]+)\Z/)
    newvalues(/\Apeer\slocal\Z/)
    newvalues(/\Aprobability\s(\d+)\Z/)
    newvalues(/\Atag\s(\d+)\Z/)

    def insync?(current)
      @should.each do |value|
        return false unless current.include?(value)
      end

      current.each do |value|
        return false unless @should.include?(value)
      end

      true
    end

    def should_to_s(value)
      value.inspect
    end
  end

  newproperty(:on_match) do
    desc %q{ Exit policy on matches. }

    newvalues(/\Agoto\s(\d+)\Z/)
    newvalues(/\Anext\Z/)
  end

  newproperty(:set, :array_matching => :all) do
    desc %q{ Set values in destination routing protocol. }

    newvalues(/\Aaggregator\sas\s(\d+)\Z/)
    newvalues(/\Aas-path\sexclude(\s(\d+))+\Z/)
    newvalues(/\Aas-path\sprepend(\s(\d+))+\Z/)
    newvalues(/\Aas-path\sprepend\slast-as\s(\d+)\Z/)
    newvalues(/\Aatomic-aggregate\Z/)
    newvalues(/\Acomm-list\s(\d+|\w[\w-]+)\sdelete\Z/)
    newvalues(/\Acommunity(\s(\d+:\d+))+(\sadditive)?\Z/)
    newvalues(/\Acommunity\snone\Z/)
    newvalues(/\Aforwarding-adsress\s([\d:]+)\Z/)
    newvalues(/\Aip\snext-hop\s((\d+\.\d+\.\d+\.\d+)|peer-address)\Z/)
    newvalues(/\Aipv6\snext-hop\s(global|local)\s([\d:]+)\Z/)
    newvalues(/\Aipv6\snext-hop\speer-address\Z/)
    newvalues(/\Alocal-preference\s(\d+)\Z/)
    newvalues(/\Ametric\s(\+|-)?(rtt|\d+)\Z/)
    newvalues(/\Ametric-type\stype-(1|2)\Z/)
    newvalues(/\Aorigin\s(egp|igp|incomplete)\Z/)
    newvalues(/\Aoriginator-id\s(\d+\.\d+\.\d+\.\d+)\Z/)
    newvalues(/\Asrc\s(\d+\.\d+\.\d+\.\d+)\Z/)
    newvalues(/\Atag\s(\d+)\Z/)
    newvalues(/\Avpn4\snext-hop\s(\d+\.\d+\.\d+\.\d+)\Z/)
    newvalues(/\Aweight\s(\d+)\Z/)

    def insync?(current)
      @should.each do |value|
        return false unless current.include?(value)
      end

      current.each do |value|
        return false unless @should.include?(value)
      end

      true
    end

    def should_to_s(value)
      value.inspect
    end
  end

  autonotify(:quagga_bgp_peer) do
    name = self[:name].split(/:/).first
    bgp_neighbors = catalog.resources.select { |resource| resource.type == :quagga_bgp_peer }
    bgp_neighbors.select { |resource| resource[:route_map_in] == name || resource[:route_map_out] == name }
  end

  autorequire(:package) do
    %w{quagga}
  end

  autorequire(:service) do
    %w{zebra bgpd ospfd}
  end
end