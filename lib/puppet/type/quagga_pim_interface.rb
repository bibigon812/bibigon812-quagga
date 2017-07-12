require 'ipaddr'

Puppet::Type.newtype(:quagga_pim_interface) do
  @doc = 'This type provides the capabilities to manage Quagga pim interface parameters'

  newparam(:name, :namevar => true) do
    desc 'The network interface name'
  end

  newproperty(:multicast, :boolean => true) do
    desc 'Enable multicast flag for the interface.'

    defaultto(:false)
    newvalues(:true, :false)
  end

  newproperty(:igmp, :boolean => true) do
    desc 'Enable IGMP.'

    defaultto(:false)
    newvalues(:true, :false)
  end

  newproperty(:pim_ssm, :boolean => true) do
    desc 'Enable PIM SSM operation.'

    defaultto(:false)
    newvalues(:true, :false)
  end

  newproperty(:igmp_query_interval) do
    desc 'IGMP query interval.'

    validate do |value|
      fail "IGMP query interval '#{value}' is not an Integer" unless value.is_a?(Integer)
      fail "IGMP query interval '#{value}' must be between 1-1800" unless value >= 1 and value <= 1800
    end

    defaultto(125)
  end

  newproperty(:igmp_query_max_response_time_dsec) do
    desc 'IGMP maximum query response time in deciseconds.'

    validate do |value|
      fail "IGMP max query response time '#{value}' is not an Integer" unless value.is_a?(Integer)
      fail "IGMP max query response time '#{value}' must be between 10-250" unless value >= 10 and value <= 250
    end

    defaultto(100)
  end

  autorequire(:package) do
    %w{quagga}
  end

  autorequire(:service) do
    %w{zebra pimd}
  end
end
