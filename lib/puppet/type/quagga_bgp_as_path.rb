Puppet::Type.newtype(:quagga_bgp_as_path) do
  @doc = %q{
    This type provides the capabilities to manage BGP as-path access-list within puppet.

      Examples:

        quagga_bgp_as_path { 'as100':
            ensure => present,
            rules => [
                'permit _100$',
                'permit _100_',
            ],
        }
  }

  ensurable

  newparam(:name) do
    desc %q{ The name of the as-path access-list. }

    newvalues(/\A\w+\Z/)
  end

  newproperty(:rules, :array_matching => :all) do
    desc 'Array of rules `action regex`.'

    newvalues(/\A(permit|deny)\s\^?[_\d\.\\\*\+\[\]\|\?]+\$?\Z/)

    def should_to_s(newvalue = @should)
      if newvalue
        newvalue.inspect
      else
        nil
      end
    end
  end

  autorequire(:package) do
    %w{quagga}
  end

  autorequire(:service) do
    %w{zebra bgpd}
  end
end
