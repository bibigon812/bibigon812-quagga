Puppet::Type.newtype(:ospf) do
  @doc = %q{This type provides the capabilites to manage ospf router within
    puppet.

    Example:

    ospf { 'ospf':
      ensure              => present,
      abr_type            => cisco,
      opaque              => true,
      rfc1583             => true,
      default_information => originate,
      network             => [ '10.0.0.0/24 area 0.0.0.0', ],
      redistribute        => [ 'connected route-map CONNECTED', ],
      router_id           => '192.168.0.1',
    }
  }

  ensurable

  newparam(:name) do
    desc %q{Name must be 'ospf'.}

    newvalues :ospf
  end

  newproperty(:abr_type) do
    desc %q{ Set OSPF ABR type }

    newvalues :cisco, :ibm, :shortcut, :standard
    defaultto :cisco
  end


  newproperty(:default_information) do
    desc %q{ Control distribution of default information }

    newvalues /\A(originate( always)?( metric \d+)?( metric-type (1|2))?( route-map [\w-]+)?)?\Z/
  end

  newproperty(:router_id) do
    desc %q{ Router-id for the OSPF process }

    newvalues(/\A(\d+\.\d+\.\d+\.\d+)?\Z/)
  end

  newproperty(:network, :array_matching => :all) do
    desc %q{ Enable routing on an IP network }

    newvalues /\A\d+\.\d+\.\d+\.\d+\/\d+ area \d+\.\d+\.\d+\.\d+\Z/

    def is_to_s value
      value.sort.inspect
    end

    def should_to_s value
      value.sort.inspect
    end
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
