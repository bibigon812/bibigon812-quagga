Puppet::Type.newtype(:pim_interface) do
  @doc = 'This type provides the capabilities to manage PIM parameters of network interfaces within puppet'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The friendly name of the network interface'
  end

  newproperty(:igmp, :boolean => true) do
    desc 'Enable IGMP'
    defaultto(:true)
    newvalues(:true, :false)
  end

  newproperty(:pim_ssm, :boolean => true) do
    desc 'Enable PIM SSM operation'
    defaultto(:true)
    newvalues(:true, :false)
  end

  newproperty(:igmp_query_interval) do
    desc 'IGMP query interval'

    validate do |value|
      raise ArgumentError, "IGMP query interval '#{value}' is not an Integer" unless value.is_a?(Integer)
      raise ArgumentError, "IGMP query interval '#{value}' must be between 1-1800" unless value >= 1 and value <= 1800
    end

    defaultto(125)
  end

  newproperty(:igmp_query_max_response_time_dsec) do
    desc 'IGMP maximum query response time in deciseconds'

    validate do |value|
      raise ArgumentError, "IGMP max query response time '#{value}' is not an Integer" unless value.is_a?(Integer)
      raise ArgumentError, "IGMP max query response time '#{value}' must be between 10-250" unless value >= 10 and value <= 250
    end

    defaultto(100)
  end

  autorequire(:package) do
    ["quagga"]
  end

  autorequire(:service) do
    ["zebra", "pimd"]
  end
end
