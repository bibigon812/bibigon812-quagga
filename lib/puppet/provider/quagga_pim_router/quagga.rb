Puppet::Type.type(:quagga_pim_router).provide :quagga do
  @doc = 'Manages quagga PIM router settings'

  @resource_map = {
    ip_multicast_routing: {
      regexp: %r{\Aip\smulticast-routing\Z},
        template: 'ip multicast-routing',
        type: :boolean,
        default: :false,
    }
  }

  commands vtysh: 'vtysh'

  def initialize(value)
    super(value)
    @property_flush = {}
  end

  def self.instances
    debug '[instances]'

    hash = {
      name: 'pim'
    }

    @resource_map.each do |property, options|
      hash[property] = options[:default]
    end

    config = vtysh('-c', 'show running-config')
    config.split(%r{\n}).map do |line|
      # comment
      next if %r{\A!\Z}.match?(line)

      @resource_map.each do |property, options|
        next unless line =~ options[:regexp]
        value = Regexp.last_match(1)

        hash[property] = if value.nil?
                           :true
                         else
                           case options[:type]
                           when :boolean
                             :true

                           when :fixnum
                             value.to_i

                           when :symbol
                             value.to_sym

                           else
                             value

                           end
                         end

        break
      end
    end

    [new(hash)]
  end

  def self.prefetch(resources)
    resources[resources.keys.first].provider = instances.first
  end

  def flush
    resource_map = self.class.instance_variable_get('@resource_map')
    name = @property_hash[:name].nil? ? @resource[:name] : @property_hash[:name]

    debug "[flush][#{name}]"

    cmds = []
    cmds << 'configure terminal'

    @property_flush.each do |property, v|
      if (v == :false) || (v == :absent)
        cmds << "no #{ERB.new(resource_map[property][:template]).result(binding)}"
      elsif (v == :true) && (resource_map[property][:type] == :symbol)
        cmds << "no #{ERB.new(resource_map[property][:template]).result(binding)}"
        cmds << ERB.new(resource_map[property][:template]).result(binding)
      elsif v == :true
        cmds << ERB.new(resource_map[property][:template]).result(binding)
      else
        encrypted = @resource[:service_password_encryption] if property == :password
        value = v
        cmds << ERB.new(resource_map[property][:template]).result(binding)
      end

      @property_hash[property] = v
    end

    cmds << 'end'
    cmds << 'write memory'
    return if @property_flush.empty?
    vtysh(cmds.reduce([]) { |cmdsx, cmd| cmdsx << '-c' << cmd })
    @property_flush.clear
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
