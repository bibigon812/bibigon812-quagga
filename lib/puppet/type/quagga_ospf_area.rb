Puppet::Type.newtype(:quagga_ospf_area) do
  @doc = "
    This type provides the capabilities to manage ospf area within puppet.

      Examples:

        ospf_area { '0.0.0.0':
            auth               => true,
            stub               => true,
            access_list_export => 'ACCESS_LIST_EXPORT',
            access_list_import => 'ACCESS_LIST_IPMORT',
            prefix_list_export => 'PREFIX_LIST_EXPORT',
            prefix_list_import => 'PREFIX_LIST_IMPORT',
            networks           => [ '10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16' ],
        }
  "

  ensurable

  newparam(:name) do
    desc ' OSPF area, ex. `0.0.0.0`. '

    block = %r{\d{,2}|1\d{2}|2[0-4]\d|25[0-5]}
    re = %r{\A#{block}\.#{block}\.#{block}\.#{block}\Z}

    newvalues(re)
  end

  newproperty(:auth) do
    desc 'OSPF authentication.'

    defaultto(:false)
    newvalues(:false, :true, 'message-digest')
  end

  newproperty(:stub) do
    desc 'Configure the OSPF area to be a stub area.'

    defaultto(:false)
    newvalues(:false, :true, 'no-summary')
  end

  newproperty(:access_list_export) do
    desc 'Set the filter for networks announced to other areas.'

    newvalues(%r{\A[[:alpha:]][\w-]+\Z})
    newvalues(:absent)
    defaultto(:absent)
  end

  newproperty(:access_list_import) do
    desc 'Set the filter for networks from other areas announced to the specified one.'

    newvalues(%r{\A[[:alpha:]][\w-]+\Z})
    newvalues(:absent)
    defaultto(:absent)
  end

  newproperty(:prefix_list_export) do
    desc 'Filter networks sent from this area.'

    newvalues(%r{\A[[:alpha:]][\w-]+\Z})
    newvalues(:absent)
    defaultto(:absent)
  end

  newproperty(:prefix_list_import) do
    desc 'Filter networks sent to this area.'

    newvalues(%r{\A[[:alpha:]][\w-]+\Z})
    newvalues(:absent)
    defaultto(:absent)
  end

  newproperty(:networks, array_matching: :all) do
    desc 'Enable routing on an IP network.'

    validate do |value|
      begin
        IPAddr.new value
      rescue
        raise ArgumentError, "Not a valid network address '#{value}'"
      end
      raise ArgumentError, "Prefix length is not specified '#{value}'" unless value.include?('/')
    end

    def insync?(is)
      @should.each do |value|
        return false unless is.include?(value)
      end

      is.each do |value|
        return false unless @should.include?(value)
      end

      true
    end

    def should_to_s(value = @should)
      if value
        value.inspect
      else
        nil
      end
    end

    defaultto([])
  end

  autorequire(:quagga_ospf_router) do
    ['ospf']
  end

  autorequire(:package) do
    ['quagga']
  end

  autorequire(:service) do
    ['zebra', 'ospfd']
  end
end
