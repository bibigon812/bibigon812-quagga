Puppet::Type.newtype(:bgp_network) do
  @doc = %q{
    This type provides the capability to manage bgp neighbor within
    puppet.

    Examples:

      bgp_network { '65000 192.168.0.0/24':
        ensure => present,
      }

      bgp_network { '65000 2a00::/64':
        ensure => present,
      }
  }

  ensurable

  newparam(:name) do
    desc %q{ It's consists of a AS number and a network IP address }

    newvalues(/\A\d+\s+(\d{,2}|1\d{2}|2[0-4]\d|25[0-5])\.(\d{,2}|1\d{2}|2[0-4]\d|25[0-5])\.(\d{,2}|1\d{2}|2[0-4]\d|25[0-5])\.(\d{,2}|1\d{2}|2[0-4]\d|25[0-5])\/(1?\d|2\d|3[0-2])\Z/)
    newvalues(/\A\d+\s+[\h:]\/(1[0-1]\d|12[0-8]|\d{1,2})\Z/)

    munge do |value|
      value.gsub(/\s+/, ' ')
    end
  end

  autorequire(:bgp) do
    reqs = []
    as = value(:name).split(/\s+/).first

    unless as.nil?
      reqs << as
    end

    reqs
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