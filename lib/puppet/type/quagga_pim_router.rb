Puppet::Type.newtype(:quagga_pim_router) do
  @doc = 'This type provides the capabilities to manage the PIM router'

  newparam(:name, namevar: true) do
    desc 'PIM router instance.'

    munge do |_value|
      'pim'
    end
  end

  newproperty(:ip_multicast_routing, boolean: true) do
    desc 'Enable IP multicast forwarding.'
    defaultto(:false)
    newvalues(:true, :false)
  end

  autorequire(:package) do
    ['quagga', 'frr']
  end

  autorequire(:service) do
    ['zebra', 'frr', 'pimd']
  end
end
