Puppet::Type.newtype(:quagga_router) do
  @doc = 'This type provides the capabilities to manage the router'

  newparam(:name, :namevar => true) do
    desc 'Router instance name'
  end

  newproperty(:hostname) do
    desc 'Router hostname'
    defaultto {@resource[:name]}
  end

  newproperty(:password) do
    desc 'Set password for vty interface. If there is no password, a vty won’t accept connections.'

    defaultto(:absent)
  end

  newproperty(:enable_password) do
    desc 'Set enable password'

    defaultto(:absent)
  end

  newproperty(:line_vty, :boolean => true) do
    desc 'Enter vty configuration mode'

    defaultto(:true)
    newvalues(:true, :false)
  end

  newproperty(:service_password_encryption, :boolean => true) do
    desc 'Encrypt passwords'

    defaultto(:false)
    newvalues(:true, :false)
  end

  autorequire(:package) do
    ['quagga']
  end

  autorequire(:service) do
    ['zebra']
  end
end
