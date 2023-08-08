Puppet::Type.newtype(:quagga_bgp_as_path) do
  @doc = "
    This type provides the capabilities to manage BGP as-path access-list within puppet.

      Examples:

        quagga_bgp_as_path { 'as100':
            ensure => present,
            rules => [
                'permit _100$',
                'permit _100_',
            ],
        }
  "

  ensurable

  newparam(:name) do
    desc 'The name of the as-path access-list.'
    newvalues(%r{\A\w+\Z})
  end

  newproperty(:rules, array_matching: :all) do
    desc 'Set actions of this ap-path list.'

    newvalues(%r{\A(permit|deny)\s\^?[_,\d\.\\\*\+\-\[\]\(\)\{\}\|\?]+\$?\Z})

    def should_to_s(newvalue = @should)
      if newvalue
        newvalue.inspect
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
