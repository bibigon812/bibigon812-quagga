Puppet::Type.newtype(:pim) do
  @doc = 'This type provides the capabilities to manage PIM within puppet'

  newparam(:name, :namevar => true) do
    desc 'PIM instance name'
    newvalues :quagga
  end

  newproperty(:multicast_routing, :boolean => true) do
    desc 'Enable IP multicast forwarding'
    defaultto(:true)
    newvalues(:true, :false)
  end

  autorequire(:package) do
    ["quagga"]
  end

  autorequire(:service) do
    ["zebra", "pimd"]
  end
end
