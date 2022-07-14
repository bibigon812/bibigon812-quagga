Puppet::Type.newtype(:quagga_ospf_area_range) do
  @doc = "
    This type provides the capabilities to manage ospf area range within puppet.

      Examples:

        ospf_area_name { '0.0.0.0 10.0.0.0/24':
          cost       => 100,
          advertise  => true,
          substitute => '10.0.0.0/8',
        }
  "

  ensurable

  newparam(:name, namevar: true) do
    desc "Contains an OSPF area id and CIDR, ex. '0.0.0.0 10.0.0.0/24'"

    block = %r{\d{,2}|1\d{2}|2[0-4]\d|25[0-5]}

    newvalues(%r{\A#{block}\.#{block}\.#{block}\.#{block}\s#{block}\.#{block}\.#{block}\.#{block}/(?:[1-2]?[0-9]|3[0-2])\Z})
  end

  newparam(:advertise) do
    desc 'Advertise this range. Defaults to `true`'

    defaultto(:true)
    newvalues(:false, :true)
  end

  newproperty(:cost) do
    desc 'User specified metric for this range'
    validate do |value|
      if (value != :absent) && (!value.is_a?(Integer) || (value < 0) || (value > 16_777_215))
        raise "Invalid value '#{value}'. Allowed values are '0-16777215'"
      end
    end

    defaultto :absent
  end

  newproperty(:substitute) do
    desc 'Network prefix to be announced instead of range'

    block = %r{\d{,2}|1\d{2}|2[0-4]\d|25[0-5]}

    newvalues(%r{\A#{block}\.#{block}\.#{block}\.#{block}/(?:[1-2]?[0-9]|3[0-2])\Z})
  end

  autorequire(:quagga_ospf_area) do
    [ self[:name].split(%r{\s+})[0] ]
  end
end
