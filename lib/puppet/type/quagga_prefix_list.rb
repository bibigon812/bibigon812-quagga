Puppet::Type.newtype(:quagga_prefix_list) do
  @doc = %q{
    This type provides the capability to manage prefix-lists within puppet.

      Example:

        quagga_prefix_list {'TEST_PREFIX_LIST:10':
          ensure => present,
          action => permit,
          prefix => '224.0.0.0/4',
          ge     => 8,
          le     => 24,
        }
  }

  ensurable

  newparam :name do
    desc 'Name of the prefix-list and sequence number of rule.'

    newvalues /\A[\w-]+:\d+\Z/

    isnamevar
  end

  newproperty :proto do
    desc 'IP protocol version: `ip`, `ipv6`. Default to `ip`.'

    newvalues :ip, :ipv6

    defaultto {
      if @resource[:prefix].nil?
        :ip
      else
        @resource[:prefix].to_s.include?(':') ? :ipv6 : :ip
      end
    }
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
        raise ArgumentError, 'Invalid value. Minimum prefix length: 1-32'
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
        raise ArgumentError, 'Invalid value. Maximum prefix length: 1-32'
      end
    end

    munge do |value|
      value.to_i
    end
  end

  autorequire(:package) do
    %w{quagga}
  end

  autorequire(:service) do
    %w{zebra}
  end
end