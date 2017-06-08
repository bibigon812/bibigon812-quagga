Puppet::Type.newtype(:bgp) do
  @doc = %q{

    This type provides the capability to manage bgp parameters within puppet.

      Examples:

        bgp { '65000':
            ensure             => present,
            import_check       => true,
            ipv4_unicast       => false,
            maximum_paths_ebgp => 10,
            maximum_paths_ibgp => 10,
            router_id          => '192.168.1.1',
        }
  }

  ensurable

  newparam(:name) do
    desc %q{ The AS number }
    newvalues(/\A\d+\Z/)
  end

  newproperty(:import_check) do
    desc %q{ Check BGP network route exists in IGP. Default to `disabled`. }

    newvalues(:false, :true)
    defaultto(:false)
  end

  newproperty(:ipv4_unicast) do
    desc %q{ Activate ipv4-unicast for a peer by default. Default to `enabled`. }

    newvalues(:false, :true)
    defaultto(:true)
  end

  newproperty(:maximum_paths_ebgp) do
    desc %q{ Forward packets over multiple paths ebgp. Default to `1`. }

    defaultto(1)
    newvalues(/\A([1-9]|[1-5][0-9]|6[0-4])\Z/)

    munge do |value|
      value.to_i
    end
  end

  newproperty(:maximum_paths_ibgp) do
    desc %q{ Forward packets over multiple paths ibgp. Default to `1`. }

    defaultto(1)
    newvalues(/\A([1-9]|[1-5][0-9]|6[0-4])\Z/)

    munge do |value|
      value.to_i
    end
  end

  newproperty(:router_id) do
    desc %q{ Override configured router identifier }

    block = /\d{,2}|1\d{2}|2[0-4]\d|25[0-5]/
    re = /\A#{block}\.#{block}\.#{block}\.#{block}\Z/

    newvalues(re)
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
