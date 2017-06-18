Puppet::Type.type(:quagga_ip).provide :quagga do
  @doc = 'Manages Quagga IP parameters'

  @resource_map = {
    :forwarding => {
      :regexp => /\Aip\sforwarding\Z/,
      :template => 'ip forwarding',
      :type => :boolean,
      :default => :false
    },
    :multicast_routing => {
      :regexp => /\Aip\smulticast-routing\Z/,
      :template => 'ip multicast-routing',
      :type => :boolean,
      :default => :false
    },
  }

  commands :vtysh => 'vtysh'

  def initialize(value)
    super(value)
    @property_flush = {}
  end

  def self.instances
    debug '[instances]'

    hash = {
      :name => :quagga
    }

    @resource_map.each do |property, options|
      hash[property] = options[:default]
    end

    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|
      # comment
      next if line =~ /\A!\Z/

      @resource_map.each do |property, options|
        if line =~ options[:regexp]
          value = $1

          case options[:type]
            when :boolean
              value = :true
          end

          hash[property] = value

          break
        end
      end
    end

    [new(hash)]
  end

  def self.prefetch(resources)
    providers = instances
    resources.keys.each do |name|
      if provider = providers.find { |provider| provider.name == name }
        resources[name].provider = provider
      end
    end
  end

  def flush
    resource_map = self.class.instance_variable_get('@resource_map')
    name = @property_hash[:name].nil? ? @resource[:name] : @property_hash[:name]

    debug "[flush][#{name}]"

    cmds = []
    cmds << 'configure terminal'

    @property_flush.each do |property, value|
      if value == :false
        cmds << 'no ' + ERB.new(resource_map[property][:template]).result(binding)
      else
        cmds << ERB.new(resource_map[property][:template]).result(binding)
      end

      @property_hash[property] = value
    end

    cmds << 'end'
    cmds << 'write memory'
    unless @property_flush.empty?
      vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })
      @property_flush.clear
    end
  end

  @resource_map.keys.each do |property|
    define_method "#{property}" do
      @property_hash[property] || :absent
    end

    define_method "#{property}=" do |value|
      @property_flush[property] = value
    end
  end
end
