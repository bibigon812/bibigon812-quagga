Puppet::Type.newtype(:quagga_prefix_list) do
  @doc = %q{
    This type provides the capability to manage prefix-lists within puppet.

      Example:

        quagga_prefix_list {'TEST_PREFIX_LIST 10':
          ensure      => present,
          action      => permit,
          ge          => 8,
          le          => 24,
          prefix      => '224.0.0.0/4',
          proto       => 'ip',
        }
  }

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the prefix-list.'

    newvalues(/\A[\w-]+\s\d+\Z/)
  end

  newproperty(:action) do
    desc 'The action of this rule.'
    defaultto(:permit)
    newvalues(:deny, :permit)
  end

  newproperty(:ge) do
    desc 'Minimum prefix length to be matched.'
    defaultto(:absent)

    validate do |value|
      return if value == :absent
      fail "Invalid value. '#{value}' is not an Integer" unless value.is_a?(Integer)
      fail 'Invalid value. Maximum prefix length: 1-32' unless value >= 1 and value <= 32
    end
  end

  newproperty(:le) do
    desc 'Maximum prefix length to be matched.'
    defaultto(:absent)

    validate do |value|
      return if value == :absent
      fail "Invalid value. '#{value}' is not an Integer" unless value.is_a?(Integer)
      fail 'Invalid value. Maximum prefix length: 1-32' unless value >= 1 and value <= 32
    end
  end

  newproperty(:prefix) do
    desc 'The IP prefix `<network>/<length>`.'
    newvalues(/\A([\d\.:\/]+|any)\Z/)
  end

  newproperty(:proto) do
    desc 'The IP protocol version.'

    newvalues(:ip, :ipv6)

    defaultto {
      if @resource[:prefix].nil?
        :ip
      else
        @resource[:prefix].to_s.include?(':') ? :ipv6 : :ip
      end
    }
  end

  autorequire(:package) do
    %w{quagga}
  end

  autorequire(:service) do
    %w{zebra}
  end
end
