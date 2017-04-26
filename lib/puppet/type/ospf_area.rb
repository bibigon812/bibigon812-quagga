Puppet::Type.newtype(:ospf_area) do
  @doc = %q{ OSPF area parameters

    Example:

      ospf_area { '0.0.0.0':
        default_cost       => 10,
        access_list_export => 'ACCESS_LIST_EXPORT',
        access_list_import => 'ACCESS_LIST_IPMORT',
        prefix_list_export => 'PREFIX_LIST_EXPORT',
        prefix_list_import => 'PREFIX_LIST_IMPORT',
        network            => [ '10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16' ],
        shortcut           => 'default',
      }

      ospf_area { '0.0.0.1':
        stub => true,
      }

      ospf_area { '0.0.0.2':
        stub => 'no-summary',
      }
  }

  ensurable

  newparam(:name) do
    desc %q{ OSPF area }

    block = /\d{,2}|1\d{2}|2[0-4]\d|25[0-5]/
    re = /\A#{block}\.#{block}\.#{block}\.#{block}\Z/

    newvalues(re)
  end

  newproperty(:default_cost) do
    desc %q{ Set the summary-default cost of a NSSA or stub area }

    newvalues(/\A\d+\Z/)

    munge do |value|
      value.to_i
    end
  end

  newproperty(:access_list_export) do
    desc %q{ Set the filter for networks announced to other areas }

    newvalues(/\A[[:alpha:]][\w-]+\Z/)

    munge do |value|
      value.to_s
    end
  end

  newproperty(:access_list_import) do
    desc %q{ Set the filter for networks from other areas announced to the specified one }

    newvalues(/\A[[:alpha:]][\w-]+\Z/)

    munge do |value|
      value.to_s
    end
  end

  newproperty(:prefix_list_export) do
    desc %q{ Filter networks sent from this area }

    newvalues(/\A[[:alpha:]][\w-]+\Z/)

    munge do |value|
      value.to_s
    end
  end

  newproperty(:prefix_list_import) do
    desc %q{ Filter networks sent to this area }

    newvalues(/\A[[:alpha:]][\w-]+\Z/)

    munge do |value|
      value.to_s
    end
  end

  newproperty(:network, :array_matching => :all) do
    desc %q{ Enable routing on an IP network }

    block = /\d{,2}|1\d{2}|2[0-4]\d|25[0-5]/
    re = /\A#{block}\.#{block}\.#{block}\.#{block}\/(\d|[1-2][\d]|3[0-2])\Z/

    newvalues(re)
  end

  newproperty(:shortcut) do
    desc %q{ Configure the area's shortcutting mode }

    newvalues(:disable, :default, :enable, :false, :true)
    defaultto(:default)

    munge do |value|
      case value
        when :false, 'false', false
          :disable
        when :true, 'true', true
          :enable
        when 'default'
          :default
        when String
          value.to_sym
        else
          value
      end
    end
  end

  newproperty(:stub) do
    desc %q{ Configure OSPF area as stub }

    newvalues(:disable, :enable, :false, :true, :no_summary)
    newvalues('no-summary')
    defaultto(:false)

    munge do |value|
      case value
        when :false, 'false', false
          :disable
        when :true, 'true', true
          :enable
        when 'no-summary', 'no_summary'
          :no_summary
        when String
          value.to_sym
        else
          value
      end
    end
  end
end
