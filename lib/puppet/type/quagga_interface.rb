require 'ipaddr'

Puppet::Type.newtype(:quagga_interface) do
  @doc = 'This type provides the capabilities to manage Quagga interface parameters'

  feature :enableable, "The provider can enable and disable the interface", :methods => [:disable, :enable, :enabled?]

  newproperty(:enable, :required_features => :enableable) do
     desc 'Whether the interface should be enabled or not'

     newvalue(:true) do
       provider.enable
     end

     newvalue(:false) do
       provider.disable
     end

     def retrieve
       provider.enabled?
     end
  end

  ensurable do
    defaultvalues
    defaultto(:present)
  end

  newparam(:name, :namevar => true) do
    desc 'The network interface name'
  end

  newproperty(:description) do
    desc 'Interface description'
    defaultto(:absent)
  end

  newproperty(:ip_address, :array_matching => :all) do
    desc 'IP address'

    validate do |value|
      begin
        IPAddr.new value
      rescue
        raise ArgumentError, "Not a valid ip address '#{value}'"
      end
      raise ArgumentError, "Prefix length is not specified '#{value}'" unless value.include?('/')
    end

    def insync?(current)
      return false if current == :absent

      current.each do |v|
        return false unless @should.include?(v)
      end

      @should.each do |v|
        return false unless current.include?(v)
      end

      true
    end

    def should_to_s(newvalue = @should)
      if newvalue
        newvalue.inspect
      else
        nil
      end
    end

    defaultto([])
  end

  newproperty(:link_detect, :boolean => true) do
    desc 'Enable link state detection'

    defaultto(:false)
    newvalues(:true, :false)
  end

  newproperty(:bandwidth) do
    desc 'Set bandwidth value of the interface in kilobits/sec'

    defaultto(:absent)

    validate do |value|
      if value != :absent
        raise ArgumentError, "Interface bandwidth '#{value}' is not an Integer" unless value.is_a?(Integer)
        raise ArgumentError, "Interface bandwidth '#{value}' must be between 1-10000000" unless value >= 1 and value <= 10000000
      end
    end
  end

  newproperty(:multicast, :boolean => true) do
    desc 'Enable multicast flag for the interface'

    defaultto(:false)
    newvalues(:true, :false)
  end

  newproperty(:igmp, :boolean => true) do
    desc 'Enable IGMP'

    defaultto(:false)
    newvalues(:true, :false)
  end

  newproperty(:pim_ssm, :boolean => true) do
    desc 'Enable PIM SSM operation'

    defaultto(:false)
    newvalues(:true, :false)
  end

  newproperty(:igmp_query_interval) do
    desc 'IGMP query interval'

    validate do |value|
      raise ArgumentError, "IGMP query interval '#{value}' is not an Integer" unless value.is_a?(Integer)
      raise ArgumentError, "IGMP query interval '#{value}' must be between 1-1800" unless value >= 1 and value <= 1800
    end

    defaultto(125)
  end

  newproperty(:igmp_query_max_response_time_dsec) do
    desc 'IGMP maximum query response time in deciseconds'

    validate do |value|
      raise ArgumentError, "IGMP max query response time '#{value}' is not an Integer" unless value.is_a?(Integer)
      raise ArgumentError, "IGMP max query response time '#{value}' must be between 10-250" unless value >= 10 and value <= 250
    end

    defaultto(100)
  end

  newproperty(:ospf_cost) do
    desc 'Interface OSPF cost'

    validate do |value|
      raise ArgumentError, "OSPF cost '#{value}' is not an Integer" unless value.is_a?(Integer)
      raise ArgumentError, "OSPF cost '#{value}' must be between 1-65535" unless value >= 1 and value <= 65535
    end

    defaultto(10)
  end

  newproperty(:ospf_dead_interval) do
    desc  'Interval after which an OSPF neighbor is declared dead'

    validate do |value|
      raise ArgumentError, "OSPF dead interval '#{value}' is not an Integer" unless value.is_a?(Integer)
      raise ArgumentError, "OSPF dead interval '#{value}' must be between 1-65535" unless value >= 1 and value <= 65535
    end

    defaultto(40)
  end

  newproperty(:ospf_hello_interval) do
    desc 'HELLO packets interval between OSPF neighbours'

    validate do |value|
      raise ArgumentError, "OSPF hello packets interval '#{value}' is not an Integer" unless value.is_a?(Integer)
      raise ArgumentError, "OSPF hello packets interval '#{value}' must be between 1-65535" unless value >= 1 and value <= 65535
    end

    defaultto(10)
  end

  newproperty(:ospf_mtu_ignore, :boolean => true) do
    desc 'Disable OSPF mtu mismatch detection'

    defaultto(:false)
    newvalues(:true, :false)
  end

  newproperty(:ospf_network) do
    desc 'OSPF network type'

    newvalues(/\A(broadcast|non-broadcast|point-to-multipoint|point-to-point|loopback)\Z/)
    defaultto('broadcast')
  end

  newproperty(:ospf_priority) do
    desc 'Router OSPF priority'

    validate do |value|
      raise ArgumentError, "Router OSPF priority '#{value}' is not an Integer" unless value.is_a?(Integer)
      raise ArgumentError, "Router OSPF priority '#{value}' must be between 1-65535" unless value >= 1 and value <= 255
    end

    defaultto(1)
  end

  newproperty(:ospf_retransmit_interval) do
    desc 'Time between retransmitting lost OSPF link state advertisements'

    validate do |value|
      raise ArgumentError, "OSPF retransmit interval '#{value}' is not an Integer" unless value.is_a?(Integer)
      raise ArgumentError, "OSPF retransmit interval '#{value}' must be between 3-65535" unless value >= 3 and value <= 65535
    end

    defaultto(5)
  end

  newproperty(:ospf_transmit_delay) do
    desc 'Link state transmit delay'

    validate do |value|
      raise ArgumentError, "OSPF transmit delay '#{value}' is not an Integer" unless value.is_a?(Integer)
      raise ArgumentError, "OSPF transmit delay '#{value}' must be between 3-65535" unless value >= 1 and value <= 65535
    end

    defaultto(1)
  end

  autorequire(:package) do
    %w{quagga}
  end

  autorequire(:service) do
    if value(:pim_ssm) == :true
      %w{quagga ospfd pimd}
    else
      %w{quagga ospfd}
    end
  end
end
