Puppet::Type.newtype(:quagga_prefix_list) do
  @doc = %q{

This type provides the capability to manage prefix-lists within puppet.

Example:

```puppet
  prefix_list {'TEST_PREFIX_LIST:10':
    ensure => present,
    action => permit,
    prefix => '224.0.0.0/4',
    ge     => 8,
    le     => 24,
  }
```

  }

  ensurable

  newparam(:name) do
    desc %q{ Name of the prefix-list and sequence number of rule. }

    newvalues(/\A[\w-]+:\d+\Z/)
  end

  newproperty(:proto) do
    desc %q{ IP protocol version: `ip`, `ipv6`. Default to `ip`. }

    defaultto :ip
    newvalues(:ip, :ipv6)
  end

  newproperty(:action) do
    desc %q{ Action can be `permit` or `deny`. }
    newvalues(:deny, :permit)
  end

  newproperty(:prefix) do
    desc %q{ IP prefix `<network>/<length>`. }

    newvalues(/\A([\d\.:\/]+|any)\Z/)
  end

  newproperty(:ge) do
    desc %q{ Minimum prefix length to be matched. }
    newvalues(/^\d+$/)

    validate do |value|
      value_i = value.to_i
      if value_i < 1 or value_i > 32
        raise ArgumentError, 'Minimum prefix length: 1-32'
      end
    end

    munge do |value|
      value.to_i
    end
  end

  newproperty(:le) do
    desc %q{ Maximum prefix length to be matched. }
    newvalues(/^\d+$/)

    validate do |value|
      value_i = value.to_i
      if value_i < 1 or value_i > 32
        raise ArgumentError, 'Maximum prefix length: 1-32'
      end
    end

    munge do |value|
      value.to_i
    end
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
        %w{zebra bgpd ospfd}
      else
        []
    end
  end
end