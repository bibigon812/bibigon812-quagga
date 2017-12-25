Puppet::Type.newtype(:quagga_ospf_area_range) do
  @doc = %q{
    This type provides the capabilities to manage ospf area range within puppet.

      Examples:

        ospf_area_name { '0.0.0.0 10.0.0.0/24':
          cost       => 100,
          advertise  => true,
          substitute => '10.0.0.0/8',
        }
  }

  ensurable

  newparam(:name, namevar: true) do
    desc "Contains an OSPF area id and CIDR, ex. '0.0.0.0 10.0.0.0/24'"

    block = /\d{,2}|1\d{2}|2[0-4]\d|25[0-5]/

    newvalues(/\A#{block}\.#{block}\.#{block}\.#{block}\s#{block}\.#{block}\.#{block}\.#{block}\/(?:[1-2]?[0-9]|3[0-2])\Z/)
  end

  newparam(:advertise) do
    desc 'Advertise this range. Defaults to `true`'

    defaultto(:true)
    newvalues(:false, :true)
  end

  newproperty(:cost) do
    desc 'User specified metric for this range'
    validate do |value|
      if value != :absent and (not value.is_a?(Integer) or value < 0 or value > 16777215)
        fail "Invalid value '#{value}'. Allowed values are '0-16777215'"
      end
    end

    defaultto :absent
  end

  newproperty(:substitute) do
    desc 'Network prefix to be announced instead of range'

    block = /\d{,2}|1\d{2}|2[0-4]\d|25[0-5]/

    newvalues(/\A#{block}\.#{block}\.#{block}\.#{block}\/(?:[1-2]?[0-9]|3[0-2])\Z/)
  end

  autorequire(:quagga_ospf_area) do
    [ self[:name].split(/\s+/)[0] ]
  end
end
