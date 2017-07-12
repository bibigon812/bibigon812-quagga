require 'ipaddr'

Puppet::Type.newtype(:quagga_interface) do
  @doc = 'This type provides the capabilities to manage Quagga interface parameters'

  feature :enableable, "The provider can enable and disable the interface", :methods => [:disable, :enable, :enabled?]

  newproperty(:enable, :required_features => :enableable) do
     desc 'Whether the interface should be enabled or not.'

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
    desc 'Interface description.'
    defaultto(:absent)
  end

  newproperty(:ip_address, :array_matching => :all) do
    desc 'The IP address.'

    validate do |value|
      begin
        IPAddr.new value
      rescue
        fail "Not a valid ip address '#{value}'"
      end
      fail "Prefix length is not specified '#{value}'" unless value.include?('/')
    end

    def insync?(is)
      is.each do |value|
        return false unless @should.include?(value)
      end

      @should.each do |value|
        return false unless is.include?(value)
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

    def change_to_s(is, should)
      "removing #{(is - should).inspect}, adding #{(should - is).inspect}."
    end

    defaultto([])
  end

  newproperty(:link_detect, :boolean => true) do
    desc 'Enable link state detection.'

    defaultto(:false)
    newvalues(:true, :false)
  end

  newproperty(:bandwidth) do
    desc 'Set bandwidth value of the interface in kilobits/sec.'

    defaultto(:absent)

    validate do |value|
      unless value == :absent
        fail "Interface bandwidth '#{value}' is not an Integer" unless value.is_a?(Integer)
        fail "Interface bandwidth '#{value}' must be between 1-10000000" unless value >= 1 and value <= 10000000
      end
    end
  end

  autorequire(:package) do
    %w{quagga}
  end

  autorequire(:service) do
    %w{zebra}
  end
end
