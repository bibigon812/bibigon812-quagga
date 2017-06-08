Puppet::Type.newtype(:quagga_ip) do
  @doc = 'This type provides the capabilities to manage Quagga IP settings'

  newparam(:name, :namevar => true) do
    desc 'Quagga instance name (must be \'quagga\')'
    newvalues :quagga
  end

  newproperty(:multicast_routing, :boolean => true) do
    desc 'Enable IP multicast forwarding'
    defaultto(:true)
    newvalues(:true, :false)
  end

  newproperty(:forwarding, :boolean => true) do
    desc 'Enable IP multicast forwarding'
    defaultto(:true)
    newvalues(:true, :false)
  end

  autorequire(:package) do
    ["quagga"]
  end

  autorequire(:service) do
    if self[:multicast_routing]
      ["zebra", "pimd"]
    else
      ["zebra"]
    end
  end
end
