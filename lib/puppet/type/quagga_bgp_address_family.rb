Puppet::Type.newtype(:quagga_bgp_address_family) do
  @doc = "
    This type provides capabilities to manage Quagga bgp address family parameters.

      Examples:

        quagga_bgp_address_family { 'ipv4_unicast':
          aggregate_address  => '192.168.0.0/24 summary-only',
          maximum_ebgp_paths => 2,
          maximum_ibgp_paths => 2,
          networks           => ['192.168.0.0/24', '172.16.0.0/24',],
        }
  "

  ensurable

  newparam(:name, namevar: true) do
    desc 'The Address family.'
    newvalues(%r{\Aipv4_(unicast|multicast)\Z})
    newvalues(%r{\Aipv6_unicast\Z})
  end

  newproperty(:aggregate_address, array_matching: :all) do
    desc 'Configure BGP aggregate entries.'

    defaultto([])
    newvalues(%r{\A(\d+\.\d+\.\d+\.\d+/\d+)(\sas-set)?(\ssummary-only)?\Z})
    newvalues(%r{\A([\h:/]+)(\ssummary-only)?\Z})

    validate do |value|
      super(value)

      v = value.split(%r{\s}).first
      proto, = resource[:name].split(%r{_})

      begin
        ip = IPAddr.new(v)
        raise "Invalid value '#{value}'. The IP address must be a v4." if (proto == 'ipv4') && ip.ipv6?
        raise "Invalid value '#{value}'. The IP address must be a v6." if (proto == 'ipv6') && ip.ipv4?
      rescue
        raise "Invalid value #{value}. The IP address '#{v}' is invalid."
      end
    end

    def insync?(is)
      is.each do |v|
        return false unless @should.include?(v)
      end

      @should.each do |v|
        return false unless is.include?(v)
      end

      true
    end

    def should_to_s(value)
      value.inspect
    end

    def to_s?(value)
      value.inspect
    end

    def change_to_s(is, should)
      "removing #{(is - should).inspect}, adding #{(should - is).inspect}."
    end
  end

  newproperty(:maximum_ebgp_paths) do
    desc 'Forward packets over multiple paths.'

    defaultto(1)
    newvalues(%r{\A\d+\Z})

    validate do |value|
      super(value)

      v = Integer(value)
      proto, type = resource[:name].split(%r{_})

      raise "Invalid value '#{value}'. Valid values are 1-255." unless (v >= 1) && (v <= 255)
      raise "Invalid value '#{value}'. The ipv4 multicast does not support multipath." if (proto == 'ipv4') && (type == 'multicast') && (v > 1)
      raise "Invalid value '#{value}'. The ipv6 does not support multipath." if (proto == 'ipv6') && (v > 1)
    end

    munge do |value|
      case value
      when String
        value.to_i
      else
        value
      end
    end
  end

  newproperty(:maximum_ibgp_paths) do
    desc 'Forward packets over multiple paths.'

    defaultto(1)
    newvalues(%r{\A\d+\Z})

    validate do |value|
      super(value)

      v = Integer(value)
      proto, type = resource[:name].split(%r{_})

      raise "Invalid value '#{value}'. Valid values are 1-255." unless (v >= 1) && (v <= 255)
      raise "Invalid value '#{value}'. The ipv4 multicast does not support multipath." if (proto == 'ipv4') && (type == 'multicast') && (v > 1)
      raise "Invalid value '#{value}'. The ipv6 does not support multipath." if (proto == 'ipv6') && (v > 1)
    end

    munge do |value|
      Integer(value)
    end
  end

  newproperty(:networks, array_matching: :all) do
    desc 'Specify a network to announce via BGP.'

    defaultto([])
    newvalues(%r{\A[\h\.:]+/\d+\Z})

    validate do |value|
      super(value)

      proto, type = resource[:name].split(%r{_})

      begin
        ip = IPAddr.new(value)

        raise "Invalid value '#{value}'. The IP address must be a v4." if (proto == 'ipv4') && !ip.ipv4?
        raise "Invalid value '#{value}'. The IP address must be a v6." if (proto == 'ipv6') && !ip.ipv6?

        raise "Invalid value '#{value}'. It is not an unicast IP address." if (proto == 'ipv4') && (type == 'unicast') && IPAddr.new('224.0.0.0/4').include?(ip)
        raise "Invalid value '#{value}'. It is not an multicast IP address." if (proto == 'ipv4') && (type == 'multicast') && !IPAddr.new('224.0.0.0/4').include?(ip)
      rescue
        raise "Invalid value '#{value}'. The IP address '#{value}' is invalid."
      end
    end

    def insync?(is)
      is.each do |v|
        return false unless @should.include?(v)
      end

      @should.each do |v|
        return false unless is.include?(v)
      end

      true
    end

    def should_to_s(value)
      value.inspect
    end

    def to_s?(value)
      value.inspect
    end

    def change_to_s(is, should)
      "removing #{(is - should).inspect}, adding #{(should - is).inspect}."
    end
  end

  autorequire(:quagga_bgp_router) do
    ['bgp']
  end

  autorequire(:package) do
    ['quagga']
  end

  autorequire(:service) do
    ['zebra', 'bgpd']
  end
end
