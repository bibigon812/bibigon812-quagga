Puppet::Type.type(:ospf_interface).provide :quagga do
  @doc = %q{Manages the interface ospf parameters using quagga}

  @resource_map = {
    :cost                 => { :regexp => /\A\sip\sospf\scost\s(\d+)\Z/, :template => 'ip ospf cost <%= value %>', :type => :Fixnum, :default => 10, },
    :dead_interval        => { :regexp => /\A\sip\sospf\sdead-interval\s(\d+)\Z/, :template => 'ip ospf dead-interval <%= value %>', :type => :Fixnum, :default => 40, },
    :hello_interval       => { :regexp => /\A\sip\sospf\shello-interval\s(\d+)\Z/, :template => 'ip ospf hello-interval <%= value %>', :type => :Fixnum, :default => 10, },
    :mtu_ignore           => { :regexp => /\A\sip\sospf\smtu-ignore\Z/, :template => 'ip ospf mtu-ignore', :type => :Symbol, :default => :disabled, },
    :network              => { :regexp => /\A\sip\sospf\snetwork\s([\w-]+)\Z/, :template => 'ip ospf network <%= value %>', :type => :Symbol, :default => :broadcast, },
    :priority             => { :regexp => /\A\sip\sospf\spriority\s(\d+)\Z/, :template => 'ip ospf priority <%= value %>', :type => :Fixnum, :default => 1, },
    :retransmit_interval  => { :regexp => /\A\sip\sospf\sretransmit-interval\s(\d+)\Z/, :template => 'ip ospf retransmit-interval <%= value %>', :type => :Fixnum, :default => 5, },
    :transmit_delay       => { :regexp => /\A\sip\sospf\stransmit-delay\s(\d+)\Z/, :template => 'ip ospf transmit-delay <%= value %>', :type => :Fixnum, :default => 1, },
  }

  @known_booleans = [
    :mtu_ignore,
  ]

  commands :vtysh => 'vtysh'

  def initialize(value)
    super(value)
    @property_flush = {}
  end

  def self.instances
    ospf_interfaces = []
    debug '[instances]'

    found_interface = false
    hash = {}
    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|
      next if line =~ /\A!\Z/
      if line =~ /\Ainterface\s([\w\d\.]+)\Z/
        name = $1
        found_interface = true

        unless hash.empty?
          debug "ospf interface: #{hash}"
          ospf_interfaces << new(hash)
        end

        hash = {}

        hash[:ensure] = :present
        hash[:provider] = self.name
        hash[:name] = name

        @resource_map.each do |property, options|
          hash[property] = options[:default]
        end

      elsif line =~ /\A\w/ and found_interface
        found_interface = false
      elsif found_interface
        @resource_map.each do |property, options|
          if line =~ options[:regexp]
            value = $1

            # mtu-ignore
            if value.nil?
              value = :enabled

            # other properties
            else
              case options[:type]
                when :Fixnum
                  value = value.to_i
                when :Symbol
                  value = value.gsub(/-/, '_').to_sym
              end
            end

            hash[property] = value

            break
          end
        end
      end
    end

    unless hash.empty?
      debug "ospf interface: #{hash}"
      ospf_interfaces << new(hash)
    end

    ospf_interfaces
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

  def destroy
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def flush
    resource_map = self.class.instance_variable_get('@resource_map')
    name = @property_hash[:name].nil? ? @resource[:name] : @property_hash[:name]

    debug "[flush][#{name}]"

    cmds = []
    cmds << 'configure terminal'
    cmds << "interface #{name}"

    @property_flush.each do |property, value|
      if value == :disable
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
