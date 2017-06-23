Puppet::Type.newtype(:quagga_redistribution) do
  @doc = %q{
    This type provides the capability to manage protocol redistributions within puppet.

      Examples:

        redistribution { 'ospf::connected':
            metric      => 100,
            metric_type => 2,
            route_map   => WORD,
        }

        redistribution { 'bgp:65000:ospf':
            metric    => 100,
            route_map => WORD,
        }
  }

  ensurable

  newparam(:name) do
    desc 'The name contains the main protocol, the id and the protocol for redistribution.'

    newvalues(/\Aospf::(kernel|connected|static|rip|isis|bgp)\Z/)
    newvalues(/\Abgp:\d+:(connected|kernel|ospf|rip|static)\Z/)
  end

  newproperty(:metric) do
    desc %q{ Metric for redistributed routes. }

    newvalues(/\A\d+\Z/)

    munge do |value|
      value.to_i
    end
  end

  newproperty(:metric_type) do
    desc 'OSPF exterior metric type for redistributed routes.'

    newvalues(/\A1\Z/)

    munge do |value|
      value.to_i
    end
  end

  newproperty(:route_map) do
    desc 'Route map reference.'

    newvalues(/\A\w+\Z/)

    munge do |value|
      value.to_s
    end
  end

  autorequire(:quagga_bgp) do
    main_protocol, as, _ = self[:name].split(/:/)
    if main_protocol == 'bgp'
      ["#{as}"]
    else
      []
    end
  end

  autorequire(:quagga_ospf) do
    main_protocol, _, _ = self[:name].split(/:/)
    if main_protocol == 'ospf'
      ['ospf']
    else
      []
    end
  end

  autorequire(:package) do
    %w{quagga}
  end

  autorequire(:service) do
    main_protocol, _, protocol = self[:name].split(/:/).first

    protocols = [main_protocol, protocol]
    reqs = %w{zebra}

    protocols.each do |protocol|
      if [:bgp, :ospf, :rip,].include?(protocol)
        reqs << protocol
      end
    end

    reqs
  end
end
