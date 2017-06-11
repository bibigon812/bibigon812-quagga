Puppet::Type.type(:bgp).provide :quagga do
  @doc = %q{ Manages as-path access-list using quagga }

  commands :vtysh => 'vtysh'

  @resource_map = {
      :import_check => {
          :default => :false,
          :regexp => /\A\sbgp\snetwork\simport-check\Z/,
          :template => 'bgp network import-check',
          :type => :boolean,
          :value => ':true',
      },
      :ipv4_unicast => {
          :default => :true,
          :regexp => /\A\sno\sbgp\sdefault\sipv4-unicast\Z/,
          :template => 'bgp default ipv4-unicast',
          :type => :boolean,
          :value => ':false',
      },
      :maximum_paths_ebgp => {
          :default => 1,
          :regexp => /\A\smaximum-paths\s(\d+)\Z/,
          :template => 'maximum-paths<% unless value.nil? %> <%= value %><% end %>',
          :type => :fixnum,
          :value => '$1',
      },
      :maximum_paths_ibgp => {
          :default => 1,
          :regexp => /\A\smaximum-paths\sibgp\s(\d+)\Z/,
          :template => 'maximum-paths ibgp<% unless value.nil? %> <%= value %><% end %>',
          :type => :fixnum,
          :value => '$1',
      },
      :router_id => {
          :regexp => /\A\sbgp\srouter-id\s(\d+\.\d+\.\d+\.\d+)\Z/,
          :template => 'bgp router-id<% unless value.nil? %> <%= value %><% end %>',
          :type => :string,
          :value => '$1',
      },
  }

  def initialize(value)
    super(value)
    @property_flush = {}
  end

  def self.instances
    debug '[instances]'

    providers = []
    found_bgp = false
    hash = {}

    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|
      next if line =~ /\A!/
      if line =~ /\Arouter\sbgp\s(\d+)\Z/
        name = $1
        found_bgp = true

        hash = {
            :ensure => :present,
            :name => name,
            :provider => self.name,
        }

        # Added default values
        @resource_map.each do |property, options|
          if options.has_key?(:default)
            hash[property] = options[:default]
          end
        end

      # Exit
      elsif line =~ /\A\w/ and found_bgp
        break

      elsif found_bgp
        @resource_map.each do |property, options|
          if line =~ options[:regexp]

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
      providers << new(hash)
    end
    providers
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
    debug '[create]'

    resource_map = self.class.instance_variable_get('@resource_map')

    @property_hash[:ensure] = :present
    @property_hash[:name] = @resource[:name]

    resource_map.keys.each do |property|
      self.method("#{property}=").call(@resource[property]) unless @resource[property].nil?
    end
  end

  def default_router_id
    def_router_id = :absent
    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|
      if line =~ /\A\sbgp\srouter-id\s(\S)\Z/
        def_router_id = $1
        break
      end
    end
    def_router_id
  end

  def destroy
    name = @property_hash[:name]

    debug "[destroy][#{name}]"

    cmds = []
    cmds << 'configure terminal'
    cmds << "no router bgp #{name}"
    cmds << 'end'
    cmds << 'write memory'

    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })

    @property_hash.clear
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

    @property_flush.each do |property, v|
      if v == :absent or v == :false
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