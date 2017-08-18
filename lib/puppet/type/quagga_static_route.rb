Puppet::Type.newtype(:quagga_static_route) do
  @doc = %q{
    This type provides the capability to manage static routes within puppet.

      Example:

        quagga_static_route {'172.16.2.0/23':
          ensure      => present,
          gateway     => '192.168.1.10',
          interface   => 'eth0',
          distance    => 10,
        }
  }

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the destination address.'

    newvalues(/\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,3}\Z/)
  end

  newproperty(:gateway) do
    desc 'The is the ip address of the gateway.'

    defaultto(:absent)
    newvalues(:absent)
    newvalues(/\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\Z/)
  end

  newproperty(:interface) do
    desc 'The exit interface for the route.'

    defaultto(:absent)
    newvalues(:absent)
    newvalues(/\A\w+\Z/)

    validate do |value|
      unless value == :absent
        fail "Not a valid interface '#{value}'" unless %x[ip addr | awk ' /^[1-9]/ {$IF = substr($2, 0, length($2)-1); print $IF}'].include?(value)
      end
    end
  end

  newproperty(:distance) do
    desc 'The administrative distance of the route.'

    defaultto(:absent)

    validate do |value|
      unless value == :absent
        fail "Invalid value. '#{value}' is not an Integer" unless value.is_a?(Integer)
        fail 'Invalid value. Maximum prefix length: 1-32' unless value >= 1 and value <= 255
      end
    end
  end


  autorequire(:package) do
    %w{quagga}
  end

  autorequire(:service) do
    %w{zebra}
  end
end
