Puppet::Type.newtype(:ospf) do
  @doc = %q{
    This type provides the capabilities to manage ospf router within puppet.

      Examples:

        ospf { 'ospf':
            ensure    => present,
            abr_type  => cisco,
            opaque    => true,
            rfc1583   => true,
            router_id => '192.168.0.1',
        }
  }

  ensurable

  newparam(:name) do
    desc %q{ Name must be 'ospf'. }

    newvalues :ospf
  end

  newproperty(:abr_type) do
    desc %q{ Set OSPF ABR type. Default to `cisco`. }

    newvalues :cisco, :ibm, :shortcut, :standard
    defaultto :cisco

    munge do |value|
      case value
        when String
          value.to_sym
        else
          value
      end
    end
  end

  newproperty(:opaque, :boolean => true) do
    desc %q{ Enable the Opaque-LSA capability (rfc2370). Default to `disabled`. }

    defaultto(:false)
    newvalues(:false, :true)
  end

  newproperty(:rfc1583, :boolean => true) do
    desc %q{ Enable the RFC1583Compatibility flag. Default to `disabled`. }

    defaultto(:false)
    newvalues(:false, :true)
  end

  newproperty(:router_id) do
    desc %q{ Router-id for the OSPF process. }

    block = /\d{,2}|1\d{2}|2[0-4]\d|25[0-5]/
    re = /\A#{block}\.#{block}\.#{block}\.#{block}\Z/

    newvalues(re)
  end

  autorequire(:package) do
    case value(:provider)
      when :quagga
        %w{quagga}
      else
        []
    end
  end

  autorequire(:service) do
    case value(:provider)
      when :quagga
        %w{zebra ospfd}
      else
        []
    end
  end
end
