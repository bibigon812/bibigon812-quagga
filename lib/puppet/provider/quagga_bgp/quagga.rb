Puppet::Type.type(:quagga_bgp).provide :quagga do
  @doc = %q{ Manages as-path access-list using quagga }

  commands :vtysh => 'vtysh'

  @resource_map = {
      :import_check => {
          :default => :false,
          :regexp => /\A\sbgp\snetwork\simport-check\Z/,
          :template => 'bgp network import-check',
          :type => :boolean,
      },
      :ipv4_unicast => {
          :default => :true,
          :regexp => /\A\sno\sbgp\sdefault\sipv4-unicast\Z/,
          :template => 'bgp default ipv4-unicast',
          :type => :boolean,
      },
      :maximum_paths_ebgp => {
          :default => 1,
          :regexp => /\A\smaximum-paths\s(\d+)\Z/,
          :template => 'maximum-paths<% unless value.nil? %> <%= value %><% end %>',
          :type => :fixnum,
      },
      :maximum_paths_ibgp => {
          :default => 1,
          :regexp => /\A\smaximum-paths\sibgp\s(\d+)\Z/,
          :template => 'maximum-paths ibgp<% unless value.nil? %> <%= value %><% end %>',
          :type => :fixnum,
      },
      :networks => {
          :default => [],
          :regexp => /\A\snetwork\s(\S+)\Z/,
          :template => 'network<% unless value.nil? %> <%= value %><% end %>',
          :type => :array,
      },
      :redistribute => {
          :regexp => /\A\sredistribute\s(.+)\Z/,
          :template => 'redistribute <%= value %>',
          :type => :array,
          :default => [],
      },
      :router_id => {
          :regexp => /\A\sbgp\srouter-id\s(\d+\.\d+\.\d+\.\d+)\Z/,
          :template => 'bgp router-id<% unless value.nil? %> <%= value %><% end %>',
          :type => :string,
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
          if [:array, :hash].include?(options[:type])
            hash[property] = options[:default].clone
          else
            hash[property] = options[:default]
          end
        end

      # Exit
      elsif line =~ /\A\w/ and found_bgp
        break

      elsif found_bgp
        @resource_map.each do |property, options|
          if line =~ options[:regexp]
            value = $1

            if value.nil?
              hash[property] = options[:default] == :false ? :true : :false
            else
              case options[:type]
                when :array
                  hash[property] << value

                when :fixnum
                  hash[property] = value.to_i

                when :boolean
                  hash[property] = :true

                when :symbol
                  hash[property] = value.gsub(/-/, '_').to_sym

                when :string
                  hash[property] = value
              end
            end

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
    name = @resource[:name]

    debug "[create][#{name}]"

    resource_map = self.class.instance_variable_get('@resource_map')

    cmds = []
    cmds << 'configure terminal'
    cmds << "router bgp #{name}"

    resource_map.each do |property, options|
      if @resource[property] and @resource[property] != options[:default]
        case options[:type]
          when :array
            @resource[property].each do |value|
              cmds << 'address-family ipv6' if property == :networks and value.include?(':')
              cmds << ERB.new(options[:template]).result(binding)
              cmds << 'exit-address-family' if property == :networks and value.include?(':')
            end

          when :boolean
            value = @resource[property]
            if value == :false
              cmds << "no #{ERB.new(options[:template]).result(binding)}"
            else
              cmds << ERB.new(options[:template]).result(binding)
            end

          else
            value = @resource[property]
            cmds << ERB.new(options[:template]).result(binding)
        end

      end
    end

    cmds << 'end'
    cmds << 'write memory'

    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })
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
          cmds << 'address-family ipv6' if property == :networks and value.include?(':')
          cmds << "no #{ERB.new(resource_map[property][:template]).result(binding)}"
          cmds << 'exit-address-family' if property == :networks and value.include?(':')
        end

        (v - @property_hash[property]).each do |value|
          cmds << 'address-family ipv6' if property == :networks and value.include?(':')
          cmds << ERB.new(resource_map[property][:template]).result(binding)
          cmds << 'exit-address-family' if property == :networks and value.include?(':')
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