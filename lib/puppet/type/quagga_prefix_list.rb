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
          protocol    => 'ip',
        }
  }

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the prefix-list and the sequence number of rule.'

    newvalues(/\A[\w-]+\s\d+\Z/)
  end

  newproperty(:action) do
    desc 'The action of this rule.'
    defaultto(:permit)
    newvalues(:deny, :permit)
  end

  newproperty(:ge) do
    desc 'Minimum prefix length to be matched.'
    newvalues(/\A\d+\Z/)

    validate do |value|
      super(value)
      v = Integer(value)
      fail 'Invalid value. Minimum prefix length: 1-32' unless v >= 1 and v <= 32
    end

    munge do |value|
      Integer(value)
    end

    def insync?(is)
      return false unless @should or is == :absent
      super(is)
    end
  end

  newproperty(:le) do
    desc 'Maximum prefix length to be matched.'
    newvalues(/\A\d+\Z/)

    validate do |value|
      super(value)
      v = value.to_i
      fail 'Invalid value. Maximum prefix length: 1-32' unless v >= 1 and v <= 32
    end

    munge do |value|
      Integer(value)
    end
  end

  newproperty(:prefix) do
    desc 'The IP prefix `<network>/<length>`.'
    newvalues(/\A([\d\.:\/]+|any)\Z/)
  end

  newproperty(:protocol) do
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
