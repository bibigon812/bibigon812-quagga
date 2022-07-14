Puppet::Type.newtype(:quagga_route_map) do
  @doc = "
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
  "

  ensurable

  newparam(:name, namevar: true) do
    desc 'Contains a name and a sequence of the route-map.'

    newvalues(%r{\A[[:alpha:]][\w-]+\s\d+\Z})
  end

  newproperty(:action) do
    desc 'The route-map action.'

    defaultto(:permit)
    newvalues(:deny, :permit)
  end

  newproperty(:match, array_matching: :all) do
    desc 'Match values from routing table.'

    defaultto([])
    newvalues(%r{\Aas-path\s(\w+)\Z})
    newvalues(%r{\Acommunity\s(\w+)(\s(exact-match))?\Z})
    newvalues(%r{\Aextcommunity\s(\w+)\Z})
    newvalues(%r{\Ainterface\s(\w[\w\.:]+)\Z})
    newvalues(%r{\Aip\s(address|next-hop|route-source)\s(\d+)\Z})
    newvalues(%r{\Aip\s(address|next-hop|route-source)\s(\w[\w-]+)\Z})
    newvalues(%r{\Aip\s(address|next-hop|route-source)\sprefix-list\s(\w[\w-]+)\Z})
    newvalues(%r{\Aipv6\s(address|next-hop)\s(\w[\w-]+)\Z})
    newvalues(%r{\Aipv6\s(address|next-hop)\sprefix-list\s(\w[\w-]+)\Z})
    newvalues(%r{\Alocal-preference\s(\d+)\Z})
    newvalues(%r{\Ametric\s(\d+)\Z})
    newvalues(%r{\Aorigin\s(egp|igp|incomplete)\Z})
    newvalues(%r{\Apeer\s(\d+\.\d+\.\d+\.\d+)\Z})
    newvalues(%r{\Apeer\s([\d:]+)\Z})
    newvalues(%r{\Apeer\slocal\Z})
    newvalues(%r{\Aprobability\s(\d+)\Z})
    newvalues(%r{\Atag\s(\d+)\Z})

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
    newvalues(%r{\Agoto\s(\d+)\Z})
    newvalues(%r{\Anext\Z})
  end

  newproperty(:set, array_matching: :all) do
    desc 'Set values in destination routing protocol.'

    newvalues(%r{\Aaggregator\sas\s(\d+)\Z})
    newvalues(%r{\Aas-path\sexclude(\s(\d+))+\Z})
    newvalues(%r{\Aas-path\sprepend(\s(\d+))+\Z})
    newvalues(%r{\Aas-path\sprepend\slast-as\s(\d+)\Z})
    newvalues(%r{\Aatomic-aggregate\Z})
    newvalues(%r{\Acomm-list\s(\d+|\w[\w-]+)\sdelete\Z})
    newvalues(%r{\Acommunity(\s(\d+:\d+))+(\sadditive)?\Z})
    newvalues(%r{\Acommunity\snone\Z})
    newvalues(%r{\Aforwarding-address\s([\d:]+)\Z})
    newvalues(%r{\Aip\snext-hop\s((\d+\.\d+\.\d+\.\d+)|peer-address)\Z})
    newvalues(%r{\Aipv6\snext-hop\s(global|local)\s([\d:]+)\Z})
    newvalues(%r{\Aipv6\snext-hop\speer-address\Z})
    newvalues(%r{\Alocal-preference\s(\d+)\Z})
    newvalues(%r{\Ametric\s(\+|-)?(rtt|\d+)\Z})
    newvalues(%r{\Ametric-type\stype-(1|2)\Z})
    newvalues(%r{\Aorigin\s(egp|igp|incomplete)\Z})
    newvalues(%r{\Aoriginator-id\s(\d+\.\d+\.\d+\.\d+)\Z})
    newvalues(%r{\Asrc\s(\d+\.\d+\.\d+\.\d+)\Z})
    newvalues(%r{\Atag\s(\d+)\Z})
    newvalues(%r{\Avpn4\snext-hop\s(\d+\.\d+\.\d+\.\d+)\Z})
    newvalues(%r{\Aweight\s(\d+)\Z})

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
    ['quagga']
  end

  autorequire(:service) do
    ['zebra', 'bgpd']
  end
end
