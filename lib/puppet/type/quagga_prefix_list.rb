Puppet::Type.newtype(:quagga_prefix_list) do
  @doc = "This type provides the capability to manage prefix-lists within puppet.

      Example:

      ```puppet
      quagga_prefix_list { 'TEST_PREFIX_LIST 10':
        ensure      => present,
        action      => permit,
        ge          => 8,
        le          => 24,
        prefix      => '224.0.0.0/4',
        proto       => 'ip',
      }
      ```"

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the prefix-list.'

    # newvalues(%r{\A[\w-]+\s\d+\Z})
  end

  newproperty(:action) do
    desc 'The action of this rule.'
    newvalues(:deny, :permit)
    defaultto(:permit)
  end

  newproperty(:ge) do
    desc 'Minimum prefix length to be matched.'
    defaultto(:absent)

    validate do |value|
      return if value == :absent
      raise "Invalid value. '#{value}' is not an Integer" unless value.is_a?(Integer)
      raise 'Invalid value. Maximum prefix length: 1-32' unless (value >= 1) && (value <= 32)
    end
  end

  newproperty(:le) do
    desc 'Maximum prefix length to be matched.'
    defaultto(:absent)

    validate do |value|
      return if value == :absent
      raise "Invalid value. '#{value}' is not an Integer" unless value.is_a?(Integer)
      raise 'Invalid value. Maximum prefix length: 1-32' unless (value >= 1) && (value <= 32)
    end
  end

  newproperty(:prefix) do
    desc 'The IP prefix `<network>/<length>`.'
    # newvalues(%r{\A([\h\.:/]+|any)\Z})
  end

  newproperty(:proto) do
    desc 'The IP protocol version.'

    newvalues(:ip, :ipv6)

    defaultto do
      if @resource[:prefix].nil?
        :ip
      else
        @resource[:prefix].to_s.include?(':') ? :ipv6 : :ip
      end
    end
  end

  autorequire(:package) do
    ['quagga']
  end

  autorequire(:service) do
    ['zebra']
  end
end
