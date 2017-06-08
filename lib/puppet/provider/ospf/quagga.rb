Puppet::Type.type(:ospf).provide :quagga do
  @doc = %q{ Manages ospf parameters using quagga }

  @resource_map = {
    :router_id           => 'ospf router-id',
    :opaque              => 'capability opaque',
    :rfc1583             => 'compatible rfc1583',
    :abr_type            => 'ospf abr-type',
  }

  @known_booleans = [ :opaque, :rfc1583, ]

  commands :vtysh => 'vtysh'

  def initialize value={}
    super(value)
    @property_flush = {}
    @property_remove = {}
  end

  def self.instances
    debug '[instances]'
    found_section = false
    providers = []
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
        hash[:opaque] = :false
        hash[:rfc1583] = :false
        hash[:abr_type] = :cisco
      elsif line =~ /\A\w/ and found_section
        break
      elsif found_section
        config_line = line.strip
        @resource_map.each do |property, command|
          if config_line.start_with? command
            if @known_booleans.include? property
              hash[property] = :true
            else
              config_line.slice! command
              hash[property] = case property
                                 when :abr_type
                                   config_line.strip.to_sym
                                 else
                                   config_line.strip
                               end
            end
          end
        end
      end
    end

    providers << new(hash) unless hash.empty?
    providers
  end

  def self.prefetch(resources)
    providers = instances
    resources.keys.each do |name|
      if provider = providers.find { |provider| provider.name == name }
        resources[name].provider = provider
        provider.purge
      end
    end
  end

  def create
    resource_map = self.class.instance_variable_get('@resource_map')

    @property_hash[:ensure] = :present
    @property_hash[:name] = @resource[:name]

    resource_map.keys.each do |property|
      self.method("#{property}=").call(@resource[property]) unless @resource[property].nil?
    end
  end

  def destroy
    debug '[destroy][ospf]'

    cmds = []
    cmds << 'configure terminal'
    cmds << 'no router ospf'
    cmds << 'end'
    cmds << 'write memory'

    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })

    @property_hash.clear
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def flush
    debug '[flush]'

    resource_map = self.class.instance_variable_get('@resource_map')

    cmds = []
    cmds << 'configure terminal'
    cmds << 'router ospf'

    @property_remove.each do |property, value|
      case property
        when :abr_type
          cmds << "no #{resource_map[property]} #{value}"
        else
          cmds << "no #{resource_map[property]}"
      end
    end

    @property_flush.each do |property, value|
      case value
        when :false
          cmds << "no #{resource_map[property]}"
        when :true
          cmds << "#{resource_map[property]}"
        else
          cmds << "#{resource_map[property]} #{value}"
      end
      @property_hash[property] = value
    end

    cmds << 'end'
    cmds << 'write memory'

    unless @property_flush.empty? && @property_remove.empty?
      vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })
      @property_flush.clear
      @property_remove.clear
    end
  end

  def purge
    debug '[purge]'

    @property_hash.each do |property, value|
      @proeprty_remove[property] = value if @resource[property].nil?
    end

    flush unless @property_remove.empty?
  end

  @resource_map.keys.each do |property|
    if @known_booleans.include?(property)
      define_method "#{property}" do
        @property_hash[property] || :false
      end
    else
      define_method "#{property}" do
        @property_hash[property] || :absent
      end
    end

    define_method "#{property}=" do |value|
      @property_flush[property] = value
    end
  end
end
