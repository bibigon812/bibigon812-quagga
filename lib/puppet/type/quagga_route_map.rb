Puppet::Type.newtype(:quagga_route_map) do
  @doc = %q{
    This type provides the capability to manage route-map within puppet.

      Example:

        route_map {'TEST_ROUTE_MAP 10':
            ensure   => present,
            action   => 'permit',
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
  }

  ensurable

  newparam(:name) do
    desc 'The name of the route-map and the action are separated by space.'

    newvalues(/\A\w[\w-]+\s\d+\Z/)
  end

  newproperty(:action) do
    desc 'The route-map action.'

    defaultto(:permit)
    newvalues(:deny, :permit)
  end

  newproperty(:match, :array_matching => :all) do
    desc 'Match values from routing table.'

    defaultto([])
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

    def insync?(is)
      @should.each do |value|
        return false unless is.include?(value)
      end

      is.each do |value|
        return false unless @should.include?(value)
      end

      true
    end

    def should_to_s(value)
      value.inspect
    end
  end

  newproperty(:on_match) do
    desc 'Exit policy on matches.'

    defaultto(:absent)
    newvalues(:absent)
    newvalues(/\Agoto\s(\d+)\Z/)
    newvalues(/\Anext\Z/)
  end

  newproperty(:set, :array_matching => :all) do
    desc 'Set values in destination routing protocol.'

    newvalues(/\Aaggregator\sas\s(\d+)\Z/)
    newvalues(/\Aas-path\sexclude(\s(\d+))+\Z/)
    newvalues(/\Aas-path\sprepend(\s(\d+))+\Z/)
    newvalues(/\Aas-path\sprepend\slast-as\s(\d+)\Z/)
    newvalues(/\Aatomic-aggregate\Z/)
    newvalues(/\Acomm-list\s(\d+|\w[\w-]+)\sdelete\Z/)
    newvalues(/\Acommunity(\s(\d+:\d+))+(\sadditive)?\Z/)
    newvalues(/\Acommunity\snone\Z/)
    newvalues(/\Aforwarding-address\s([\d:]+)\Z/)
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

    def insync?(is)
      @should.each do |value|
        return false unless is.include?(value)
      end

      is.each do |value|
        return false unless @should.include?(value)
      end

      true
    end

    def should_to_s(value)
      value.inspect
    end

    defaultto([])
  end

  autorequire(:package) do
    %w{quagga}
  end

  autorequire(:service) do
    %w{zebra bgpd}
  end
end
