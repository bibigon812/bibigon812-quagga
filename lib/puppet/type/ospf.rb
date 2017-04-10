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
      area                => 0.0.0.0,
      network             => '10.0.0.0/24 area 0.0.0.0',
      redistribute        => 'connected route-map CONNECTED',
      router_id           => '192.168.0.1',
    }
  }

  class String
    def is_number?
      true if Float(self) rescue false
    end
  end

  ensurable

  newparam(:name) do
    desc %q{Name must be 'ospf'.}
    newvalues :ospf
  end

  newproperty(:abr_type, :required_feature => :abr_type) do
    desc %q{Set OSPF ABR type.}

    newvalues :cisco, :ibm, :shortcut, :standard
    defaultto :cisco
  end


  newproperty(:default_information) do
    desc %q{Control distribution of default information.}

    newvalues /\A(originate( always)?( metric \d+)?( metric-type (1|2))?( route-map [\w-]+)?)?\Z/

  end

  newproperty(:redistribute, :array_matching => :all) do
    desc %q{ Redistribute information from another routing protocol. }

    protocols = [ :babel, :bgp, :connected, :isis, :kernel, :pim, :rip, :static ]
    keys = [ :metric, :metric_type, :route_map ]

    newvalues /\A(kernel|connected|static|rip|isis|bgp)( metric \d+)?( metric-type (1|2))?( route-map [\w-]+)?\Z/
  end

  newproperty(:router_id) do
    desc %q{ router-id for the OSPF process. }
    newvalues(/\A\d+\.\d+\.\d+\.\d+\Z/)
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
