Puppet::Type.newtype(:quagga_static_route) do
  @doc = "
    This type provides the capability to manage static routes within puppet.

      Example:

        quagga_static_route {'172.16.2.0/24':
          ensure      => present,
          hexthop     => '192.168.1.10',
          distance    => 10,
        }

        quagga_static_route {'172.16.3.0/24':
          ensure      => present,
          hexthop     => 'null0',
          distance    => 10,
        }
  "

  def self.title_patterns
    [
      [
        %r{\A(\S+)\Z},
        [
          [:prefix],
        ],
      ],
      [
        %r{\A(\S+)\s+(\S+)\Z},
        [
          [:prefix],
          [:nexthop],
        ],
      ],
    ]
  end

  def name
    "#{self[:prefix]} #{self[:nexthop]}"
  end

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:prefix, namevar: true) do
    desc 'IP destination prefix.'

    validate do |value|
      begin
        IPAddr.new(value)
      rescue
        raise "Not a valid ip address '#{value}'"
      end
      raise "Prefix length is not specified '#{value}'" unless value.include?('/')
    end

    munge do |value|
      _prefix, length = value.split('/')
      network = IPAddr.new(value)
      "#{network}/#{length}"
    end
  end

  newparam(:nexthop, namevar: true) do
    desc 'Specifies IP or the interface name of the nexthop router.'

    defaultto 'Null0'

    validate do |value|
      if value != 'Null0'
        raise 'Do not specify the prefix length \'%{prefix}\'.' % { prefix: value } if value.include?('/')
        begin
          IPAddr.new(value)
        rescue
          unless Facter.value(:interfaces).split(',').include?(value)
            raise 'The network interface \'%{name}\' was not found' % { name: value }
          end
        end
      end
    end
  end

  newproperty(:distance) do
    desc 'Specifies the distance value for this route.'

    defaultto(:absent)

    validate do |value|
      unless value == :absent
        raise "Invalid value '#{value}'. It is not an Integer" unless value.is_a?(Integer)
        raise 'Invalid value. Maximum prefix length: 1-32' unless (value >= 1) && (value <= 255)
      end
    end
  end

  newproperty(:option) do
    desc 'Sets reject or blackhole for this route.'

    defaultto :absent
    newvalues(:absent, :blackhole, :reject)
  end

  autorequire(:package) do
    ['quagga']
  end

  autorequire(:service) do
    ['zebra']
  end
end
