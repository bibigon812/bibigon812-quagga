Puppet::Type.newtype(:quagga_bgp_address_family) do
  @doc = %q{
    This type provides capabilities to manage Quagga bgp address family parameters.

      Examples:

        quagga_bgp_address_family { 'ipv4_unicast':
          aggregate_address  => '192.168.0.0/24 summary-only',
          maximum_ebgp_paths => 2,
          maximum_ibgp_paths => 2,
          networks           => ['192.168.0.0/24', '172.16.0.0/24',],
        }
  }

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The Address family.'
    newvalues(/\Aipv4_(unicast|multicast)\Z/)
    newvalues(/\Aipv6_unicast\Z/)
  end

  newproperty(:aggregate_address, array_matching: :all) do
    desc 'Configure BGP aggregate entries.'

    defaultto([])
    newvalues(/\A(\d+\.\d+\.\d+\.\d+\/\d+)(\sas-set)?(\ssummary-only)?\Z/)
    newvalues(/\A([\h:\/]+)(\ssummary-only)?\Z/)

    validate do |value|
      super(value)

      v = value.split(/\s/).first
      proto, _ = resource[:name].split(/_/)

      begin
        ip = IPAddr.new(v)
        fail "Invalid value '#{value}'. The IP address must be a v4." if proto == 'ipv4' and ip.ipv6?
        fail "Invalid value '#{value}'. The IP address must be a v6." if proto == 'ipv6' and ip.ipv4?
      rescue
        fail "Invalid value #{value}. The IP address '#{v}' is invalid."
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

    def is_to_s(value)
      value.inspect
    end

    def change_to_s(is, should)
      "removing #{(is - should).inspect}, adding #{(should - is).inspect}."
    end
  end

  newproperty(:maximum_ebgp_paths) do
    desc 'Forward packets over multiple paths.'

    defaultto(1)
    newvalues(/\A\d+\Z/)

    validate do |value|
      super(value)

      v = Integer(value)
      proto, type = resource[:name].split(/_/)

      fail "Invalid value '#{value}'. Valid values are 1-255." unless v >= 1 and v <= 255
      fail "Invalid value '#{value}'. The ipv4 multicast does not support multipath." if proto == 'ipv4' and type == 'multicast' and v > 1
      fail "Invalid value '#{value}'. The ipv6 does not support multipath." if proto == 'ipv6' and v > 1
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
    newvalues(/\A\d+\Z/)

    validate do |value|
      super(value)

      v = Integer(value)
      proto, type = resource[:name].split(/_/)

      fail "Invalid value '#{value}'. Valid values are 1-255." unless v >= 1 and v <= 255
      fail "Invalid value '#{value}'. The ipv4 multicast does not support multipath." if proto == 'ipv4' and type == 'multicast' and v > 1
      fail "Invalid value '#{value}'. The ipv6 does not support multipath." if proto == 'ipv6' and v > 1
    end

    munge do |value|
      Integer(value)
    end
  end

  newproperty(:networks, array_matching: :all) do
    desc 'Specify a network to announce via BGP.'

    defaultto([])
    newvalues(/\A[\h\.:]+\/\d+\Z/)

    validate do |value|
      super(value)

      proto, type = resource[:name].split(/_/)

      begin
        ip = IPAddr.new(value)

        fail "Invalid value '#{value}'. The IP address must be a v4." if proto == 'ipv4' and not ip.ipv4?
        fail "Invalid value '#{value}'. The IP address must be a v6." if proto == 'ipv6' and not ip.ipv6?

        fail "Invalid value '#{value}'. It is not an unicast IP address." if proto == 'ipv4' and type == 'unicast' and IPAddr.new('224.0.0.0/4').include?(ip)
        fail "Invalid value '#{value}'. It is not an multicast IP address." if proto == 'ipv4' and type == 'multicast' and not IPAddr.new('224.0.0.0/4').include?(ip)
      rescue
        fail "Invalid value '#{value}'. The IP address '#{value}' is invalid."
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

    def is_to_s(value)
      value.inspect
    end

    def change_to_s(is, should)
      "removing #{(is - should).inspect}, adding #{(should - is).inspect}."
    end
  end

  autorequire(:quagga_bgp_router) do
    %w{bgp}
  end

  autorequire(:package) do
    %w{quagga}
  end

  autorequire(:service) do
    %w{zebra bgpd}
  end
end
