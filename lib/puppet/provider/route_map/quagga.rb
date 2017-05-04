Puppet::Type.type(:route_map).provide :quagga do
  @doc = %q{ Manages redistribution using quagga }

  @resource_map = {
      :match => 'match',
      :on_match => 'on-match',
      :set => 'set',
  }

  commands :vtysh => 'vtysh'

  mk_resource_methods

  def initialize(value)
    super(value)
    @property_flush = {}
    @property_remove = {}
  end

  def self.instances
    debug '[instances]'

    route_maps = []
    found_route_map = false
    hash = {}

    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|
      next if line =~ /\A!\Z/
      if line =~ /\Aroute-map\s([\w-]+)\s(deny|permit)\s(\d+)\Z/
        name = $1
        action = $2
        sequence = $3
        found_route_map = true

        unless hash.empty?
          debug "route_map: #{hash.inspect}"
          route_maps << new(hash)
        end
        hash = {}
        hash[:ensure] = :present
        hash[:name] = "#{name}:#{action}:#{sequence}"
        hash[:provider] = self.name
      elsif line =~ /\A\s(match|on-match|set)\s(.+)\Z/ && found_route_map
        action = $1
        value = $2
        action = action.gsub(/-/, '_').to_sym

        if [:match, :set].include?(action)
          hash[action] ||= []
          hash[action] << value
        else
          hash[action] = value
        end
      elsif line =~ /\A\w/ && found_route_map
        break
      end
    end
    unless hash.empty?
      debug "route_map: #{hash.inspect}"
      route_maps << new(hash)
    end
    route_maps
  end

  def self.prefetch(resources)
    providers = instances
    found_providers = []
    resources.keys.each do |name|
      if provider = providers.find { |provider| provider.name == name }
        resources[name].provider = provider
        found_providers << provider
        provider.purge
      end
    end
    (providers - found_providers).each do |provider|
      provider.destroy
    end
  end

  def create
    debug '[create]'

    resource_map = self.class.instance_variable_get('@resource_map')

    @property_hash[:name] = @resource[:name]
    @property_hash[:ensure] = :present

    resource_map.keys.each do |property|
      self.method("#{property}=").call(@resource[property]) unless @resource[property].nil?
    end
  end

  def destroy
    debug '[destroy]'

    @property_hash[:ensure] = :absent
    flush
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def flush
    name, action, sequence = @property_hash[:name].split(/:/)

    debug "[flush][#{name}:#{action}:#{sequence}]"
    resource_map = self.class.instance_variable_get('@resource_map')

    cmds = []

    cmds << 'configure terminal'
    cmds << "route-map #{name} #{action} #{sequence}"

    if @property_hash[:ensure] == :absent
      cmds << "no #{cmds.last}"
    else

      @property_remove.each do |property, value|
        if [:match, :set].include?(property)
          value.each do |line|
            cmds << "no #{resource_map[property]} #{line}"
          end
        else
          cmds << "no #{resource_map[property]} #{value}"
        end
      end

      @property_remove.clear

      @property_flush.each do |property, value|
        if [:match, :set].include?(property)
          old_value = @property_hash[property] || []
          (old_value - value).each do |line|
            cmds << "no #{resource_map[property]} #{line}"
          end
          (value - old_value).each do |line|
            cmds << "#{resource_map[property]} #{line}"
          end
        else
          cmds << "#{resource_map[property]} #{value}"
        end
        @property_hash[property] = value
      end

      @property_flush.clear

    end

    cmds << 'end'
    cmds << 'write memory'

    vtysh(cmds.reduce([]){|cmds, cmd| cmds << '-c' << cmd})
  end

  def purge
    debug '[purge]'
    need_flush = false
    resource_map = self.class.instance_variable_get('@resource_map')
    resource_map.keys.each do |property|
      if @resource[property].nil? && !@property_hash[property].nil?
        @property_remove[property] = @property_hash[property]
        need_flush = true
      end
    end
    flush if need_flush
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