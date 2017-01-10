Puppet::Type.newtype(:ospf) do
  @doc = %q{This type provides the capabilites to manage ospf router within
    puppet.

    Example:

    ospf { 'ospf':
      ensure              => present,
      abr_type            => cisco,
      default_information => {
        originate   => true,
        always      => true,
        metric      => 100,
        metric_type => 2,
        route_map   => ROUTE_MAP,
      },
      network             => {
        192.168.0.0 => {
          area => 0.0.0.0,
        },
      },
      redistribute        => {
        ..
      },
      router_id           => 192.168.0.1,
    }
  }
  ensurable

  newparam(:name) do
    desc %q{Name must be 'ospf'.}
    newvalues(:ospf)
  end

  newproperty(:abr_type, :required_feature => :abr_type) do
    desc %q{Set OSPF ABR type.}

    newvalues(:cisco, :ibm, :shortcut, :standard)
    defaultto(:cisco)
  end

  newproperty(:default_information) do
    desc %q{Control distribution of default information.}

    validate do |value|
    end
    
    munge do |value|
      if value.is_a?(String)
        if value.include?('=>')
          begin
            eval(value.gsub(/(\w+)/, '\'\1\''))
          rescue SyntaxError => e
            raise ArgumentError, '%s is not a Hash' % value
          end
        else
          arr = value.split(/\s/)
          arr[0..-2].reverse.inject(arr.last) { |a, b| {b => a} }
        end
      else
        value
      end
    end
  end

  newproperty(:network) do
    desc %q{ Enable routing on an IP network. }
    munge do |value|
      if value.is_a?(String) and value.include?('=>')
        eval(value.gsub(/([\w\.\/:]+)/, '\'\1\''))
      else
        value
      end
    end
  end

  newproperty(:redistribute) do

    desc %q{ Redistribute information from another routing protocol. }
    munge do |value|
      if value.is_a?(String)
        eval(value.gsub(/(\w+)/, '\'\1\''))
      else
        value
      end
    end
  end

  newproperty(:router_id, :required_feature => :router_id) do
    desc %q{ router-id for the OSPF process. }
    newvalues(/^[\d\.]+$/)
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
