Puppet::Type.type(:quagga_pim_interface).provide :quagga do
  @doc = 'Manages quagga interface parameters'

  @resource_map = {
    multicast: {
      regexp: %r{\A\smulticast\Z},
      template: 'multicast',
      type: :boolean,
      default: :false
    },
    igmp: {
      regexp: %r{\A\sip\sigmp\Z},
      template: 'ip igmp',
      type: :boolean,
      default: :false
    },
    pim_ssm: {
      regexp: %r{\A\sip\spim\sssm\Z},
      template: 'ip pim ssm',
      type: :boolean,
      default: :false
    },
    igmp_query_interval: {
      regexp: %r{\A\sip\sigmp\squery-interval\s(\d+)\Z},
      template: 'ip igmp query-interval<% unless value.nil? %> <%= value %><% end %>',
      type: :fixnum,
      default: 125
    },
    igmp_query_max_response_time_dsec: {
      regexp: %r{\A\sip\sigmp\squery-max-response-time-dsec\s(\d+)\Z},
      template: 'ip igmp query-max-response-time-dsec<% unless value.nil? %> <%= value %><% end %>',
      type: :fixnum,
      default: 100
    },
  }

  commands vtysh: 'vtysh'

  def initialize(value)
    super(value)
    @property_flush = {}
  end

  def self.instances
    interfaces = []
    debug '[instances]'

    found_interface = false
    interface = {}

    config = vtysh('-c', 'show running-config')
    config.split(%r{\n}).map do |line|
      # skip comments
      next if %r{\A!\Z}.match?(line)

      if line =~ %r{\Ainterface\s([\w\d\.]+)\Z}
        name = Regexp.last_match(1)
        found_interface = true

        unless interface.empty?
          debug "interface: #{interface}"
          interfaces << new(interface)
        end

        interface = {
          name: name,
          provider: self.name,
        }

        @resource_map.each do |property, options|
          interface[property] = if (options[:type] == :array) || (options[:type] == :hash)
                                  options[:default].clone
                                else
                                  options[:default]
                                end
        end
      elsif line =~ (%r{\A\w}) && found_interface
        found_interface = false
      elsif found_interface
        @resource_map.each do |property, options|
          if %r{\A\sshutdown\Z}.match?(line)
            interface[:enable] = :false
          elsif line =~ options[:regexp]
            value = Regexp.last_match(1)

            if value.nil?
              interface[property] = :true
            else
              case options[:type]
              when :array
                interface[property] << value

              when :fixnum
                interface[property] = value.to_i

              when :boolean
                interface[property] = :true

              else
                interface[property] = value

              end
            end

            break
          end
        end
      end
    end

    unless interface.empty?
      debug "interface: #{interface}"
      interfaces << new(interface)
    end

    interfaces
  end

  def self.prefetch(resources)
    providers = instances
    resources.each_key do |name|
      if (provider = providers.find { |providerx| providerx.name == name })
        resources[name].provider = provider
      end
    end
  end

  def create; end

  def exists?
    true
  end

  def destroy; end

  def flush
    resource_map = self.class.instance_variable_get('@resource_map')
    name = @property_hash[:name].nil? ? @resource[:name] : @property_hash[:name]

    debug "[flush][#{name}]"

    cmds = []
    cmds << 'configure terminal'
    cmds << "interface #{name}"

    @property_flush.each do |property, v|
      if (v == :false) || (v == :absent)
        cmds << "no #{ERB.new(resource_map[property][:template]).result(binding)}"
      elsif (v == :true) && (resource_map[property][:type] == :symbol)
        cmds << "no #{ERB.new(resource_map[property][:template]).result(binding)}"
        cmds << ERB.new(resource_map[property][:template]).result(binding)
      elsif v == :true
        cmds << ERB.new(resource_map[property][:template]).result(binding)
      elsif resource_map[property][:type] == :array
        (@property_hash[property] - v).each do |value|
          cmds << "no #{ERB.new(resource_map[property][:template]).result(binding)}"
        end

        v.each do |value|
          cmds << ERB.new(resource_map[property][:template]).result(binding)
        end
      else
        value = v
        cmds << ERB.new(resource_map[property][:template]).result(binding)
      end

      @property_hash[property] = v
    end

    cmds << 'end'
    cmds << 'write memory'
    return if property_flush.empty?
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
