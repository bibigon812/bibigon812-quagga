Puppet::Type.newtype(:quagga_system) do
  @doc = 'This type provides the capabilities to manage the router'

  newparam(:name, :namevar => true) do
    desc 'Router instance name'
  end

  newproperty(:hostname) do
    desc 'Router hostname'
    defaultto {@resource[:name]}

    munge do |value|
      if value.empty?
        @resource[:name]
      else
        value
      end
    end
  end

  newproperty(:password) do
    desc 'Set password for vty interface. If there is no password, a vty won’t accept connections.'

    defaultto(:absent)

    munge do |value|
      if value.empty?
        :absent
      else
        value
      end
    end
  end

  newproperty(:enable_password) do
    desc 'Set enable password'

    defaultto(:absent)

    munge do |value|
      if value.empty?
        :absent
      else
        value
      end
    end
  end

  newproperty(:ip_multicast_routing, :boolean => true) do
    desc 'Enable IP multicast forwarding'
    defaultto(:true)
    newvalues(:true, :false)
  end

  newproperty(:ip_forwarding, :boolean => true) do
    desc 'Enable IP forwarding'
    defaultto(:true)
    newvalues(:true, :false)
  end

  newproperty(:ipv6_forwarding, :boolean => true) do
    desc 'Enable IPv6 forwarding'
    defaultto(:true)
    newvalues(:true, :false)
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
    %w{quagga}
  end

  autorequire(:service) do
    if value(:ip_multicast_routing) == :true
      %w{zebra pimd}
    else
      %w{zebra}
    end
  end
end
