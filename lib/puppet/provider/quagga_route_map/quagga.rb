Puppet::Type.type(:quagga_route_map).provide :quagga do
  @doc = 'Manages redistribution using quagga'

  @resource_map = {
    match: {
      default: [],
        regexp: %r{\A\smatch\s(.+)\Z},
        template: 'match <%= value %>',
        type: :array,
    },
    on_match: {
      default: :absent,
      regexp: %r{\A\son-match\s(.+)\Z},
      template: 'on-match <%= value %>',
      type: :string,
    },
    set: {
      default: [],
      regexp: %r{\A\sset\s(.+)\Z},
      template: 'set <%= value %>',
      type: :array,
    },
  }

  commands vtysh: 'vtysh'

  def initialize(value)
    super(value)
    @property_flush = {}
  end

  def self.instances
    providers = []
    found_route_map = false
    hash = {}

    config = vtysh('-c', 'show running-config')
    config.split(%r{\n}).map do |line|
      next if %r{\A!\Z}.match?(line)

      if line =~ %r{\Aroute-map\s([\w-]+)\s(deny|permit)\s(\d+)\Z}
        name = Regexp.last_match(1)
        action = Regexp.last_match(2)
        sequence = Integer(Regexp.last_match(3))
        found_route_map = true

        unless hash.empty?
          debug 'Instantiated the route-map %{name}' % {
            name: hash[:name],
          }

          providers << new(hash)
        end

        hash = {
          action: action.to_sym,
          ensure: :present,
          name: "#{name} #{sequence}",
          provider: self.name,
        }

        # Added default values
        @resource_map.each do |property, options|
          hash[property] = if [:array, :hash].include?(options[:type])
                             options[:default].clone
                           else
                             options[:default]
                           end
        end

      elsif line =~ (%r{\A\s+(match|on-match|set)}) && found_route_map
        @resource_map.each do |property, options|
          next unless line =~ options[:regexp]
          value = Regexp.last_match(1)

          if value.nil?
            hash[property] = :true
          else
            case options[:type]
            when :array
              hash[property] << value

            else
              hash[property] = value
            end
          end

          break
        end
      elsif line =~ %r{\Aexit} && found_route_map
        next
      elsif line =~ %r{\A\w} && found_route_map
        break
      end
    end

    unless hash.empty?
      debug 'Instantiated the route-map %{name} %{sequence}' % {
        name: hash[:name],
        sequence: hash[:sequence],
      }

      providers << new(hash)
    end

    providers
  end

  def self.prefetch(resources)
    providers = instances
    resources.each_key do |name|
      if (provider = providers.find { |providerx| providerx.name == name })
        resources[name].provider = provider
      end
    end
  end

  def create
    name, sequence = @resource[:name].split(%r{\s})
    action = @resource[:action]

    debug 'Creating the route-map %{name}' % { name: @resource[:name] }

    resource_map = self.class.instance_variable_get('@resource_map')

    cmds = []
    cmds << 'configure terminal'
    cmds << "route-map #{name} #{action} #{sequence}"

    resource_map.each do |property, options|
      next unless @resource[property] && (@resource[property] != options[:default])
      case options[:type]
      when :array
        @resource[property].each do |value|
          cmds << ERB.new(options[:template]).result(binding)
        end

      else
        value = @resource[property]
        cmds << ERB.new(options[:template]).result(binding)
      end
    end

    cmds << 'end'
    cmds << 'write memory'

    vtysh(cmds.reduce([]) { |cmdsx, cmd| cmdsx << '-c' << cmd })
  end

  def destroy
    name, sequence = @property_hash[:name].split(%r{\s})
    action = @property_hash[:action]

    debug 'Destroying the route-map #{name}' % { name: @property_hash[:name] }

    cmds = []
    cmds << 'configure terminal'
    cmds << "route-map #{name} #{action} #{sequence}"
    cmds << "no #{cmds.last}"
    cmds << 'end'
    cmds << 'write memory'

    vtysh(cmds.reduce([]) { |cmdsx, cmd| cmdsx << '-c' << cmd })
    @property_hash.clear
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def flush
    # Exit if nothing to do
    return if @property_flush.empty?

    name, sequence = @property_hash[:name].split(%r{\s})
    action = @property_hash[:action]

    debug 'Flushing the route-map %{name}' % { name: @property_hash[:name] }

    resource_map = self.class.instance_variable_get('@resource_map')

    cmds = []

    cmds << 'configure terminal'
    cmds << "route-map #{name} #{action} #{sequence}"

    @property_flush.each do |property, v|
      if (v == :false) || (v == :absent)
        cmds << "no #{ERB.new(resource_map[property][:template]).result(binding)}"

      elsif resource_map[property][:type] == :array
        (@property_hash[property] - v).each do |value|
          cmds << "no #{ERB.new(resource_map[property][:template]).result(binding)}"
        end

        (v - @property_hash[property]).each do |value|
          cmds << ERB.new(resource_map[property][:template]).result(binding)
        end

      else
        value = v
        cmds << ERB.new(resource_map[property][:template]).result(binding)
      end

      @property_hash[property] = v
    end

    @property_flush.clear

    cmds << 'end'
    cmds << 'write memory'

    vtysh(cmds.reduce([]) { |cmdsx, cmd| cmdsx << '-c' << cmd })
  end

  def action
    @property_hash[:action] || :absent
  end

  def action=(value)
    @property_hash[:action] = value
  end

  @resource_map.each_key do |property|
    define_method property.to_s do
      @property_hash[property] || :absent
    end

    define_method "#{property}=" do |value|
      @property_flush[property] = value
    end
  end
end
