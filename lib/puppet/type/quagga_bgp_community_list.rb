Puppet::Type.newtype(:quagga_bgp_community_list) do
  @doc = "
    This type provides the capability to manage BGP community-list within puppet.

      Examples:

        quagga_bgp_community_list { '100':
            ensure => present,
            rules  => [
                'permit 65000:50952',
                'permit 65000:31500',
            ],
        }
  "

  ensurable

  newparam(:name) do
    desc 'Community list number.'

    newvalues(%r{^\d+$})

    validate do |value|
      value_i = value.to_i
      if (value_i < 1) || (value_i > 500)
        raise ArgumentError, 'Community list number: 1-500.'
      end
    end
  end

  newproperty(:rules, array_matching: :all) do
    desc 'Set actions of this community list.'

    newvalues(%r{\A(deny|permit)\s\^?[_,\d\.\\\*\+\-\[\]\(\)\{\}\|\?:]+\$?\Z})

    def should_to_s(value = @should)
      if value
        value.inspect
      else
        nil
      end
    end
  end

  autorequire(:package) do
    ['quagga', 'frr']
  end

  autorequire(:service) do
    ['zebra', 'frr', 'bgpd']
  end
end
