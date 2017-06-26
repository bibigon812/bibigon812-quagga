Puppet::Type.type(:quagga_global).provide :quagga do
  @doc = 'Manages quagga router settings'

  @resource_map = {
    :hostname => {
      :regexp => /\Ahostname\s(.*)\Z/,
      :template => 'hostname<% unless value.nil? %> <%= value %><% end %>',
      :type => :string,
      :default => :absent,
    },
    :password => {
      :regexp => /\Apassword\s(?:\d\s)?(.*)\Z/,
      :template => 'password<% unless value.nil? %><% if encrypted %> 8<% end %> <%= value %><% end %>',
      :type => :string,
      :default => :absent,
    },
    :enable_password => {
      :regexp => /\Aenable\spassword\s(?:\d\s)?(.*)\Z/,
      :template => 'enable password<% unless value.nil? %><% if encrypted %> 8<% end %> <%= value %><% end %>',
      :type => :string,
      :default => :absent,
    },
    :line_vty => {
      :regexp => /\Aline\svty\Z/,
      :template => 'line vty',
      :type => :boolean,
      :default => :true,
    },
    :ip_forwarding => {
        :regexp => /\Aip\sforwarding\Z/,
        :template => 'ip forwarding',
        :type => :boolean,
        :default => :false,
    },
    :ipv6_forwarding => {
        :regexp => /\Aipv6\sforwarding\Z/,
        :template => 'ipv6 forwarding',
        :type => :boolean,
        :default => :false,
    },
    :ip_multicast_routing => {
        :regexp => /\Aip\smulticast-routing\Z/,
        :template => 'ip multicast-routing',
        :type => :boolean,
        :default => :false,
    },
    :service_password_encryption => {
      :regexp => /\Aservice\spassword-encryption\Z/,
      :template => 'service password-encryption',
      :type => :boolean,
      :default => :false,
    }
  }

  commands :vtysh => 'vtysh'

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
    config.split(/\n/).collect do |line|
      # comment
      next if line =~ /\A!\Z/

      @resource_map.each do |property, options|
        if line =~ options[:regexp]
          value = $1

          if value.nil?
            hash[property] = :true
          else
            case options[:type]
              when :boolean
                hash[property] = :true

              when :fixnum
                hash[property] = value.to_i

              when :symbol
                hash[property] = value.to_sym

              else
                hash[property] = value

            end
          end

          break
        end
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
      if v == :false or v == :absent
        cmds << "no #{ERB.new(resource_map[property][:template]).result(binding)}"
      elsif v == :true and resource_map[property][:type] == :symbol
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
