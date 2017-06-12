Puppet::Type.newtype(:quagga_ospf) do
  @doc = 'This type provides the capabilities to manage ospf router within puppet'

  ensurable

  newparam(:name) do
    desc 'OSPF router instance. Must be set to \'ospf\''

    newvalues(:ospf)
  end

  newproperty(:abr_type) do
    desc 'Set OSPF ABR type. Default to `cisco`.'

    newvalues(:cisco, :ibm, :shortcut, :standard)
    defaultto(:cisco)
  end

  newproperty(:opaque, :boolean => true) do
    desc 'Enable the Opaque-LSA capability (rfc2370). Default to `false`.'

    defaultto(:false)
    newvalues(:true, :false)
  end

  newproperty(:rfc1583, :boolean => true) do
    desc 'Enable the RFC1583Compatibility flag. Default to `false`.'

    defaultto(:false)
    newvalues(:true, :false)
  end

  newproperty(:router_id) do
    desc 'OSPF process router id'

    block = /\d{,2}|1\d{2}|2[0-4]\d|25[0-5]/
    re = /\A#{block}\.#{block}\.#{block}\.#{block}\Z/

    newvalues(:absent, re)
    defaultto(:absent)
  end

  newproperty(:log_adjacency_changes) do
    desc 'Log changes in adjacency'

    defaultto(:false)
    newvalues(:true, :false, :detail)
  end

  autorequire(:package) do
    ['quagga']
  end

  autorequire(:service) do
    ['zebra', 'ospfd']
  end
end
