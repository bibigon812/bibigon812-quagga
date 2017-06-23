Puppet::Type.newtype(:quagga_ospf_area) do
  @doc = %q{
    This type provides the capabilities to manage ospf area within puppet.

      Examples:

        ospf_area { '0.0.0.0':
            access_list_export => 'ACCESS_LIST_EXPORT',
            access_list_import => 'ACCESS_LIST_IPMORT',
            prefix_list_export => 'PREFIX_LIST_EXPORT',
            prefix_list_import => 'PREFIX_LIST_IMPORT',
            networks           => [ '10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16' ],
        }
  }

  ensurable

  newparam(:name) do
    desc %q{ OSPF area, ex. `0.0.0.0`. }

    block = /\d{,2}|1\d{2}|2[0-4]\d|25[0-5]/
    re = /\A#{block}\.#{block}\.#{block}\.#{block}\Z/

    newvalues(re)
  end

  newproperty(:access_list_export) do
    desc 'Set the filter for networks announced to other areas.'

    newvalues(/\A[[:alpha:]][\w-]+\Z/)
    newvalues(:absent)
    defaultto(:absent)
  end

  newproperty(:access_list_import) do
    desc 'Set the filter for networks from other areas announced to the specified one.'

    newvalues(/\A[[:alpha:]][\w-]+\Z/)
    newvalues(:absent)
    defaultto(:absent)
  end

  newproperty(:prefix_list_export) do
    desc 'Filter networks sent from this area.'

    newvalues(/\A[[:alpha:]][\w-]+\Z/)
    newvalues(:absent)
    defaultto(:absent)
  end

  newproperty(:prefix_list_import) do
    desc 'Filter networks sent to this area.'

    newvalues(/\A[[:alpha:]][\w-]+\Z/)
    newvalues(:absent)
    defaultto(:absent)
  end

  newproperty(:networks, :array_matching => :all) do
    desc 'Enable routing on an IP network. Default to `[]`.'

    validate do |value|
      begin
        IPAddr.new value
      rescue
        raise ArgumentError, "Not a valid network address '#{value}'"
      end
      raise ArgumentError, "Prefix length is not specified '#{value}'" unless value.include?('/')
    end

    def insync?(current)
      @should.each do |value|
        return false unless current.include?(value)
      end

      current.each do |value|
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

  autorequire(:quagga_ospf) do
    %w{ospf}
  end

  autorequire(:package) do
    %w{quagga}
  end

  autorequire(:service) do
    %w{zebra ospfd}
  end
end
