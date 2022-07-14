Puppet::Type.newtype(:quagga_access_list) do
  @doc = "
    This type provides the capability to manage BGP community-list within puppet.

      Examples:

      quagga_access_list {'1':
        ensure => present,
        remark => 'IP standard access list',
        rules  => [
          'deny 10.0.0.128 0.0.0.127',
          'deny 10.0.101.193',
          'permit 10.0.0.0 0.0.255.255',
          'permit 192.168.10.1'.
          'deny any'
        ]
      }
      quagga_access_list {'100':
        ensure   => present,
        remark   => 'IP extended access-list',
        rules    => [
          'deny ip host 10.0.1.100 any',
          'permit ip 10.0.1.0 0.0.0.255 any',
          'deny ip any any'
        ]
      }
      quagga_access_list {'a_word':
        ensure => present,
        remark => 'IP zebra access-list',
        rules  => [
          'deny 192.168.0.0/23',,
          'permit 192.168.0.0/16',
          'deny any',
        ]
      }
  "

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, namevar: true) do
    desc 'The number of this access list.'

    newvalues(%r{\A(1|\d{2}|1[3-9]\d{2})\Z})
    newvalues(%r{\A(1\d{2}|2[0-6]\d{2})\Z})
    newvalues(%r{\A[\w-]+\Z})
  end

  newproperty(:remark) do
    desc 'Specifies the remark for this access-list.'
  end

  newproperty(:rules, array_matching: :all) do
    desc 'Permits and denies for this rule.'

    defaultto []

    validate do |value|
      if %r{\A(1|\d{2}|1[3-9]\d{2})\Z}.match?(resource[:name])
        raise "Invalid value '#{value}' of the standard access-list rule." unless value.match(Regexp.union(
          %r{\A(deny|permit)\s(\d{1,3}\.){3}\d{1,3}(\s(\d{1,3}\.){3}\d{1,3})?\Z},
          %r{\A(deny|permit)\sany\Z},
        ))
      elsif %r{\A(1\d{2}|2[0-6]\d{2})\Z}.match?(resource[:name])
        raise "Invalid value '#{value}' of the extanded access-list rule." unless value.match?(
          %r{\A(deny|permit)\sip\s(any|(host|(\d{1,3}\.){3}\d{1,3})\s(\d{1,3}\.){3}\d{1,3})\s(any|(host|(\d{1,3}\.){3}\d{1,3})\s(\d{1,3}\.){3}\d{1,3})\Z},
        )
      elsif %r{\A[\w-]+\Z}.match?(resource[:name])
        raise "Invalid value '#{value}' of the zebra access-list rule." unless value.match(Regexp.union(
            %r{\A(deny|permit)\s(\d{1,3}\.){3}\d{1,3}/\d{1,2}(\sexact-match)?\Z},
            %r{\A(deny|permit)\sany\Z},
          ))
      end
    end

    def should_to_s(value = @should)
      if value
        value.inspect
      else
        nil
      end
    end
  end

  autorequire(:package) do
    ['quagga']
  end

  autorequire(:service) do
    ['zebra']
  end
end
