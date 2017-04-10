Puppet::Type.type(:ospf).provide :quagga do
  @doc = %q{Manages ospf parameters using quagga}

  @resource_map = {
    :router_id => 'ospf router-id',
    :opaque => 'capability opaque',
    :rfc1583 => 'compatible rfc1583',
    :abr_type => 'ospf abr-type',
    :reference_bandwidth => 'auto-cost  reference-bandwidth',
    :default_information => 'default-information',
    :network => 'network',
    :redistribute => 'redistribute',
  }

  @known_booleans = [ :opaque, :rfc1583, ]
  @known_arrays = [ :network, :redistribute, ]
  @hidden_booleans = %w{nssa}

  commands :vtysh => 'vtysh'

  mk_resource_methods

  def self.instances
    debug 'Instances'
    found_section = false
    ospf = []
    hash = {}
    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|
      next if line =~ /\A!\Z/
      if line =~ /\Arouter (ospf)\Z/
        as = $1
        found_section = true
        hash[:ensure] = :present
        hash[:name] = as.to_sym
        hash[:provider] = self.name
      elsif line =~ /\A\w/ and found_section
        break
      elsif found_section
        config_line = line.strip
        @resource_map.each do |property, command|
          if config_line.start_with? command
            if @known_booleans.include? property
              hash[property] = :true
            elsif @known_arrays.include? property
              hash[property] ||= []
              config_line.slice! command
              hash[property] << config_line.strip
              hash[property].sort!
            else
              config_line.slice! command
              hash[property] = config_line.strip
            end
          end
        end
      end
    end
    ospf << new(hash) unless hash.empty?
    ospf
  end

  def self.prefetch(resources)
    providers = instances
    found_providers = []
    resources.keys.each do |name|
      if provider = providers.find { |provider| provider.name == name }
        resources[name].provider = provider
        found_providers << provider
      end
    end
    (providers - found_providers).each do |provider|
      provider.destroy
    end
  end
end
