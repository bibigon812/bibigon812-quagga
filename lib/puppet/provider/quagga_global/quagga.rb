Puppet::Type.type(:quagga_global).provide :quagga do
  @doc = 'Manages quagga router settings'

  @resource_map = {
    hostname: {
      regexp: %r{\Ahostname\s(.*)\Z},
      template: 'hostname<% unless value.nil? %> <%= value %><% end %>',
      type: :string,
      default: :absent,
    },
    password: {
      regexp: %r{\Apassword\s(?:\d\s)?(.*)\Z},
      template: 'password<% unless value.nil? %><% if encrypted %> 8<% end %> <%= value %><% end %>',
      type: :string,
      default: :absent,
    },
    enable_password: {
      regexp: %r{\Aenable\spassword\s(?:\d\s)?(.*)\Z},
      template: 'enable password<% unless value.nil? %><% if encrypted %> 8<% end %> <%= value %><% end %>',
      type: :string,
      default: :absent,
    },
    line_vty: {
      regexp: %r{\Aline\svty\Z},
      template: 'line vty',
      type: :boolean,
      default: :true,
    },
    ip_forwarding: {
      regexp: %r{\Aip\sforwarding\Z},
        template: 'ip forwarding',
        type: :boolean,
        default: :false,
    },
    ipv6_forwarding: {
      regexp: %r{\Aipv6\sforwarding\Z},
        template: 'ipv6 forwarding',
        type: :boolean,
        default: :false,
    },
    service_password_encryption: {
      regexp: %r{\Aservice\spassword-encryption\Z},
      template: 'service password-encryption',
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

    hash = {}
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

    hash[:name] = hash[:hostname]

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
