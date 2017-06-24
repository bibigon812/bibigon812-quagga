Puppet::Type.newtype(:quagga_ospf) do
  @doc = %q{
    This type provides the capabilities to manage ospf router within puppet.

      Examples:

        quagga_ospf { 'ospf':
            ensure => present,
            redistribute => [
              'connected route-map QWER',
              'kernel',
            ],
            router_id => '10.0.0.1',
        }
  }

  ensurable

  newparam(:name) do
    desc 'OSPF router instance. Must be set to \'ospf\''

    newvalues(:ospf)
  end

  newproperty(:abr_type) do
    desc 'Set OSPF ABR type. Default to `cisco`.'

    newvalues(:cisco, :ibm, :shortcut, :standard)
    defaultto(:cisco)
  end

  newproperty(:opaque, :boolean => true) do
    desc 'Enable the Opaque-LSA capability (rfc2370). Default to `false`.'

    defaultto(:false)
    newvalues(:true, :false)
  end

  newproperty(:redistribute, :array_matching => :all) do
    desc 'Redistribute information from another routing protocol'

    newvalues(/\A(babel|bgp|connected|isis|kernel|rip|static)(\smetric\s\d+)?(\smetric-type\s[1-2])?(\sroute-map\s\w+)?\Z/)

    munge do |value|
      value.gsub(/\smetric-type\s2/, '')
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

    def should_to_s(value)
      value.inspect
    end

    defaultto([])
  end

  newproperty(:rfc1583, :boolean => true) do
    desc 'Enable the RFC1583Compatibility flag. Default to `false`.'

    defaultto(:false)
    newvalues(:true, :false)
  end

  newproperty(:router_id) do
    desc 'OSPF process router id'

    block = /\d{,2}|1\d{2}|2[0-4]\d|25[0-5]/
    re = /\A#{block}\.#{block}\.#{block}\.#{block}\Z/

    newvalues(:absent, re)
    defaultto(:absent)
  end

  newproperty(:log_adjacency_changes) do
    desc 'Log changes in adjacency'

    defaultto(:false)
    newvalues(:true, :false, :detail)
  end

  autorequire(:package) do
    %w{quagga}
  end

  autorequire(:service) do
    %w{zebra ospfd}
  end
end
