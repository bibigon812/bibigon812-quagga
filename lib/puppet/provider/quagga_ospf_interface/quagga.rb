Puppet::Type.type(:quagga_ospf_interface).provide :quagga do
  @doc = 'Manages quagga interface parameters'

  @resource_map = {
    :auth => {
      :regexp => /\A\sip\sospf\sauthentication\s(message-digest)\Z/,
      :template => 'ip ospf authentication<% unless value.nil? %> <%= value %><% end %>',
      :type => :string,
      :default => :absent
    },
    :message_digest_key => {
      :regexp => /\A\sip\sospf\smessage-digest-key\s(.*)\Z/,
      :template => 'ip ospf message-digest-key<% unless value.nil? %> <%= value %><% end %>',
      :type => :string,
      :default => :absent
    },
    :cost => {
      :regexp => /\A\sip\sospf\scost\s(\d+)\Z/,
      :template => 'ip ospf cost<% unless value.nil? %> <%= value %><% end %>',
      :type => :fixnum,
      :default => :absent
    },
    :dead_interval => {
      :regexp => /\A\sip\sospf\sdead-interval\s(\d+)\Z/,
      :template => 'ip ospf dead-interval<% unless value.nil? %> <%= value %><% end %>',
      :type => :fixnum,
      :default => 40
    },
    :hello_interval => {
      :regexp => /\A\sip\sospf\shello-interval\s(\d+)\Z/,
      :template => 'ip ospf hello-interval<% unless value.nil? %> <%= value %><% end %>',
      :type => :fixnum,
      :default => 10
    },
    :mtu_ignore => {
      :regexp => /\A\sip\sospf\smtu-ignore\Z/,
      :template => 'ip ospf mtu-ignore',
      :type => :boolean,
      :default => :false
    },
    :network => {
      :regexp => /\A\sip\sospf\snetwork\s([\w-]+)\Z/,
      :template => 'ip ospf network<% unless value.nil? %> <%= value %><% end %>',
      :type => :string,
      :default => :absent
    },
    :priority => {
      :regexp => /\A\sip\sospf\spriority\s(\d+)\Z/,
      :template => 'ip ospf priority<% unless value.nil? %> <%= value %><% end %>',
      :type => :fixnum,
      :default => 1
    },
    :retransmit_interval => {
      :regexp => /\A\sip\sospf\sretransmit-interval\s(\d+)\Z/,
      :template => 'ip ospf retransmit-interval<% unless value.nil? %> <%= value %><% end %>',
      :type => :fixnum,
      :default => 5
    },
    :transmit_delay => {
      :regexp => /\A\sip\sospf\stransmit-delay\s(\d+)\Z/,
      :template => 'ip ospf transmit-delay<% unless value.nil? %> <%= value %><% end %>',
      :type => :fixnum,
      :default => 1
    }
  }

  commands :vtysh => 'vtysh'

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
    config.split(/\n/).collect do |line|
      # skip comments
      next if line =~ /\A!\Z/

      if line =~ /\Ainterface\s([\w\d\.]+)\Z/
        name = $1
        found_interface = true

        unless interface.empty?
          debug "interface: #{interface}"
          interfaces << new(interface)
        end

        interface = {
          :name => name,
          :provider => self.name,
        }

        @resource_map.each do |property, options|
          if options[:type] == :array or options[:type] == :hash
            interface[property] = options[:default].clone
          else
            interface[property] = options[:default]
          end
        end
      elsif line =~ /\A\w/ and found_interface
        found_interface = false
      elsif found_interface
        @resource_map.each do |property, options|
          if line =~ /\A\sshutdown\Z/
            interface[:enable] = :false
          elsif line =~ options[:regexp]
            value = $1

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
    resources.keys.each do |name|
      if provider = providers.find { |provider| provider.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
  end

  def exists?
    true
  end

  def destroy
  end

  def flush
    resource_map = self.class.instance_variable_get('@resource_map')
    name = @property_hash[:name].nil? ? @resource[:name] : @property_hash[:name]

    debug "[flush][#{name}]"

    cmds = []
    cmds << 'configure terminal'
    cmds << "interface #{name}"

    @property_flush.each do |property, v|
      if v == :false or v == :absent
        cmds << "no #{ERB.new(resource_map[property][:template]).result(binding)}"
      elsif v == :true and resource_map[property][:type] == :symbol
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
