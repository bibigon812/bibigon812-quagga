require 'ipaddr'

Puppet::Type.newtype(:quagga_ospf_interface) do
  @doc = 'This type provides the capabilities to manage Quagga interface OSPF parameters.'

  newparam(:name, namevar: true) do
    desc 'The network interface name'
  end

  newproperty(:auth) do
    desc 'Interface OSPF authentication.'

    defaultto(:absent)
    newvalues(:absent, 'message-digest')
  end

  newproperty(:message_digest_key) do
    desc 'Set OSPF authentication key to a cryptographic password. The cryptographic algorithm is MD5.'

    defaultto(:absent)
    newvalues(:absent, %r{\d+\smd5\s\S{1,16}})
  end

  newproperty(:cost) do
    desc 'Interface OSPF cost.'

    validate do |value|
      if value != :absent
        raise "OSPF cost '#{value}' is not an Integer" unless value.is_a?(Integer)
        raise "OSPF cost '#{value}' must be between 1-65535" unless (value >= 1) && (value <= 65_535)
      end
    end

    defaultto(:absent)
  end

  newproperty(:dead_interval) do
    desc 'Interval after which an OSPF neighbor is declared dead.'

    validate do |value|
      raise "OSPF dead interval '#{value}' is not an Integer" unless value.is_a?(Integer)
      raise "OSPF dead interval '#{value}' must be between 1-65535" unless (value >= 1) && (value <= 65_535)
    end

    defaultto(40)
  end

  newproperty(:hello_interval) do
    desc 'HELLO packets interval between OSPF neighbours.'

    validate do |value|
      raise "OSPF hello packets interval '#{value}' is not an Integer" unless value.is_a?(Integer)
      raise "OSPF hello packets interval '#{value}' must be between 1-65535" unless (value >= 1) && (value <= 65_535)
    end

    defaultto(10)
  end

  newproperty(:mtu_ignore, boolean: true) do
    desc 'Disable OSPF mtu mismatch detection.'

    defaultto(:false)
    newvalues(:true, :false)
  end

  newproperty(:network) do
    desc 'OSPF network type'

    newvalues(:absent, :broadcast, 'non-broadcast', 'point-to-multipoint', 'point-to-point', :loopback)
    defaultto(:absent)
  end

  newproperty(:priority) do
    desc 'Router OSPF priority.'

    validate do |value|
      raise "Router OSPF priority '#{value}' is not an Integer" unless value.is_a?(Integer)
      raise "Router OSPF priority '#{value}' must be between 1-65535" unless (value >= 1) && (value <= 255)
    end

    defaultto(1)
  end

  newproperty(:retransmit_interval) do
    desc 'Time between retransmitting lost OSPF link state advertisements.'

    validate do |value|
      raise "OSPF retransmit interval '#{value}' is not an Integer" unless value.is_a?(Integer)
      raise "OSPF retransmit interval '#{value}' must be between 3-65535" unless (value >= 3) && (value <= 65_535)
    end

    defaultto(5)
  end

  newproperty(:transmit_delay) do
    desc 'Link state transmit delay.'

    validate do |value|
      raise "OSPF transmit delay '#{value}' is not an Integer" unless value.is_a?(Integer)
      raise "OSPF transmit delay '#{value}' must be between 3-65535" unless (value >= 1) && (value <= 65_535)
    end

    defaultto(1)
  end

  autorequire(:package) do
    ['quagga']
  end

  autorequire(:service) do
    ['zebra', 'ospfd']
  end
end
