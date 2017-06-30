Puppet::Type.newtype(:quagga_bgp_router) do
  @doc = %q{

    This type provides the capability to manage bgp parameters within puppet.

      Examples:

        quagga_bgp { '65000':
            ensure                   => present,
            import_check             => true,
            default_ipv4_unicast     => false,
            default_local_preference => 100,
            router_id                => '192.168.1.1',
        }
  }

  ensurable

  newparam(:name) do
    desc 'The AS number.'
    newvalues(/\A\d+\Z/)
  end

  newproperty(:import_check) do
    desc 'Check BGP network route exists in IGP.'

    newvalues(:false, :true)
    defaultto(:false)
  end

  newproperty(:default_ipv4_unicast) do
    desc 'Activate ipv4-unicast for a peer by default.'

    newvalues(:false, :true)
    defaultto(:true)
  end

  newproperty(:default_local_preference) do
    desc 'Default local preference.'

    defaultto(100)
    newvalues(/\A\d+\Z/)

    munge do |value|
      Integer(value)
    end
  end

  newproperty(:redistribute, :array_matching => :all) do
    desc 'Redistribute information from another routing protocol'

    defaultto([])
    newvalues(/\A(babel|connected|isis|kernel|ospf|rip|static)(\smetric\s\d+)?(\sroute-map\s\w+)?\Z/)

    def insync?(is)
      @should.each do |value|
        return false unless is.include?(value)
      end

      is.each do |value|
        return false unless @should.include?(value)
      end

      true
    end

    def is_to_s(value)
      value.inspect
    end

    def should_to_s(value)
      value.inspect
    end

    def change_to_s(is, should)
      "removing #{(is - should)}, adding #{(should - is)}."
    end
  end


  newproperty(:router_id) do
    desc %q{ Override configured router identifier }

    block = /\d{,2}|1\d{2}|2[0-4]\d|25[0-5]/
    re = /\A#{block}\.#{block}\.#{block}\.#{block}\Z/

    newvalues(re)
  end

  autorequire(:package) do
    %w{quagga}
  end

  autorequire(:service) do
    %w{zebra bgpd}
  end
end
