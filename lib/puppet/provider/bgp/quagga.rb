Puppet::Type.type(:bgp).provide :quagga do
  @doc = %q{ Manages as-path access-list using quagga }

  commands :vtysh => 'vtysh'

  @resource_map = {
      :import_check => {
          :default => :disabled,
          :regex => /\A\sbgp\snetwork\simport-check\Z/,
          :template => 'bgp network import-check',
          :type => :boolean,
          :value => ':enabled',
      },
      :ipv4_unicast => {
          :default => :enabled,
          :regex => /\A\sno\sbgp\sdefault\sipv4-unicast\Z/,
          :template => 'bgp default ipv4-unicast',
          :type => :boolean,
          :value => ':disabled',
      },
      :maximum_paths_ebgp => {
          :default => 1,
          :regex => /\A\smaximum-paths\s(\d+)\Z/,
          :template => 'maximum-paths <%= value %>',
          :type => :fixnum,
          :value => '$1',
      },
      :maximum_paths_ibgp => {
          :default => 1,
          :regex => /\A\smaximum-paths\sibgp\s(\d+)\Z/,
          :template => 'maximum-paths ibgp <%= value %>',
          :type => :fixnum,
          :value => '$1',
      },
      :router_id => {
          :regex => /\A\sbgp\srouter-id\s(\d+\.\d+\.\d+\.\d+)\Z/,
          :template => 'bgp router-id <%= value %>',
          :type => :string,
          :value => '$1',
      },
  }

  def initialize(value)
    super(value)
    @property_flush = {}
    @property_remove = {}
  end

  def self.instances
    debug '[instances]'

    bgp = []
    found_bgp = false
    hash = {}

    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|
      next if line =~ /\A!/
      if line =~ /\Arouter\sbgp\s(\d+)\Z/
        name = $1
        found_bgp = true

        hash[:ensure] = :present
        hash[:provider] = self.name
        hash[:name] = name

        # Added default values
        @resource_map.each do |property, options|
          if options.has_key?(:default)
            hash[property] = options[:default]
          end
        end
      elsif line =~ /\A\w/ and found_bgp
        break
      elsif found_bgp
        @resource_map.each do |property, options|
          if line =~ options[:regex]
            value = eval(options[:value])
            case options[:type]
              when :fixnum
                value = value.to_i
            end
            hash[property] = value

            break
          end
        end
      end
    end
    unless hash.empty?
      debug "bgp: #{hash}"
      bgp << new(hash)
    end
    bgp
  end

  def self.prefetch(resources)
    providers = instances
    found_providers = []
    resources.keys.each do |name|
      if provider = providers.find { |provider| provider.name == name }
        resources[name].provider = provider
        found_providers << provider
      end
    end
  end

  def create
    debug '[create]'

    resource_map = self.class.instance_variable_get('@resource_map')

    @property_hash[:ensure] = :present
    @property_hash[:name] = @resource[:name]

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
    name = @property_hash[:name]

    debug "[flush][#{name}]"

    resource_map = self.class.instance_variable_get('@resource_map')

    cmds = []
    cmds << 'configure terminal'
    cmds << "router bgp #{name}"

    if @property_hash == :absent
      cmds << "no router bgp #{name}"
    else
      @property_remove.each do |property, value|
        cmds << "no #{ERB.new(resource_map[property][:template]).result(binding)}"
      end

      @property_flush.each do |property, value|
        cmd = ''
        if resource_map[property][:type] == :boolean && value == :disabled
          cmd << 'no '
        end
        cmd << ERB.new(resource_map[property][:template]).result(binding)
        cmds << cmd
      end
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

    # resource_map = self.class.instance_variable_get('@resource_map')

    @resource_map.keys.each do |property|
      if @resource[property].nil? && !@property_hash[property].nil?
        @property_remove[property] = @property_hash[property]
      end
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