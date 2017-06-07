Puppet::Type.type(:pim_interface).provide :quagga do
  @doc = 'Manages the interface PIM parameters using quagga'

  @resource_map = {
    :igmp                              => { :regexp => /\A\sip\sigmp\Z/, :template => 'ip igmp', :type => :Symbol, :default => :false },
    :pim_ssm                           => { :regexp => /\A\sip\spim\sssm\Z/, :template => 'ip pim ssm', :type => :Symbol, :default => :false },
    :igmp_query_interval               => { :regexp => /\A\sip\sigmp\squery-interval\s(\d+)\Z/, :template => 'ip igmp query-interval <%= value %>', :type => :Fixnum, :default => 125 },
    :igmp_query_max_response_time_dsec => { :regexp => /\A\sip\sigmp\squery-max-response-time-dsec\s(\d+)\Z/, :template => 'ip igmp query-max-response-time-dsec <%= value %>', :type => :Fixnum, :default => 100 },
  }

  commands :vtysh => 'vtysh'

  def initialize(value)
    super(value)
    @property_flush = {}
  end

  def self.instances
    pim_interfaces = []
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
          debug "PIM interface: #{hash}"
          pim_interfaces << new(hash)
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

            if value.nil?
              value = :true
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
      debug "PIM interface: #{hash}"
      pim_interfaces << new(hash)
    end

    pim_interfaces
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
