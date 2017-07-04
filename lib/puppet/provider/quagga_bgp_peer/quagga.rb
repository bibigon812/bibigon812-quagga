Puppet::Type.type(:quagga_bgp_peer).provide(:quagga) do
  @doc = 'Manages bgp neighbors using quagga.'

  commands :vtysh => 'vtysh'

  @resource_map = {
    :peer_group => {
      :default => :false,
      :template => 'neighbor <%= name %> peer-group <%= value %>',
      :type => :string,
    },
    :remote_as => {
      :default => :absent,
      :regexp => /\A\sneighbor\s\S+\sremote-as\s(\d+)\Z/,
      :template => 'neighbor <%= name %> remote-as <%= value %>',
      :type => :fixnum,
    },
    :local_as => {
      :default => :absent,
      :regexp => /\A\sneighbor\s\S+\slocal-as\s(\d+)\Z/,
      :template => 'neighbor <%= name %> local-as<% unless value.nil? %> <%= value %><% end %>',
      :type => :fixnum,
    },
    :passive => {
      :default => :false,
      :regexp => /\A\sneighbor\s\S+\spassive\Z/,
      :template => 'neighbor <%= name %> passive',
      :type => :boolean,
    },
    :shutdown => {
      :default => :false,
      :regexp => /\A\sneighbor\s\S+\sshutdown\Z/,
      :template => 'neighbor <%= name %> shutdown',
      :type => :boolean,
    },
    :update_source => {
      :default => :absent,
      :regexp => /\A\sneighbor\s\S+\supdate-source\s(\S+)\Z/,
      :template => 'neighbor <%= name %> update-source<% unless value.nil? %> <%= value %><% end %>',
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

    hash = {}
    # activate = {}

    previous_name = name = ''
    found_router = false

    # default_ipv4_unicast = :true

    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|

      # Skip comments
      next if line =~ /\A!/

      if line =~ /\Arouter\sbgp\s(\d+)\Z/
        found_router = true

      # Store a default value of the property `ipv4_unicast`
      # elsif found_router && line =~/\A\sno\sbgp\sdefault\sipv4-unicast\Z/
      #   default_ipv4_unicast = :false

      elsif found_router && line =~ /\A\sneighbor\s(\S+)\s(peer-group|remote-as)(\s(\S+))?\Z/
        name = $1
        key = $2
        value = $4

        key = key.gsub(/-/, '_').to_sym
        value = value.to_i if key == :remote_as

        # Found a new neighbour
        unless name == previous_name
          unless hash.empty?
            debug 'Instantiated bgp peer %{name}' % { :name => hash[:name] }
            providers << new(hash)
          end

          hash = {
              :ensure => :present,
              :name => name,
              :provider => self.name,
          }

          # Add default values
          @resource_map.each do |property, options|
            if options.has_key?(:default)
              if [:array, :hash].include?(options[:type])
                hash[property] = options[:default].clone
              else
                hash[property] = options[:default]
              end
            end
          end
        end

        hash[key] = value.nil? ? :true : value

      elsif found_router && line =~ /\A\s(no\s)?neighbor\s#{Regexp.escape(name)}\s/
        @resource_map.each do |property, options|
          if options.has_key?(:regexp)
            if line =~ options[:regexp]
              value = $1

              if value == nil
                hash[property] = :true

              else
                case options[:type]
                  when :array
                    hash[property] << value

                  when :boolean
                    hash[property] = :true

                  when :symbol
                    hash[property] = value.gsub(/-/, '_').to_sym

                  when :fixnum
                    hash[property] = value.to_i

                  else
                    hash[property] = value
                end
              end

              break
            end
          end
        end

      # Exit
      elsif found_router && line =~ /\A\w/
        break
      end

      previous_name = name
    end

    unless hash.empty?
      debug 'Instantiated bgp peer %{name}' % { :name => hash[:name] }
      providers << new(hash)
    end

    providers
  end

  def self.prefetch(resources)
    providers = instances
    resources.each_key do |name|
      if provider = providers.find { |it| it.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
    name = @resource[:name]

    debug 'Creating the bgp peer %{name}' % { :name => name }

    as_number = get_as_number
    resource_map = self.class.instance_variable_get('@resource_map')

    cmds = []
    cmds << 'configure terminal'
    cmds << 'router bgp %{as_number}' % { :as_number => as_number}

    resource_map.each do |property, options|
      if @resource[property] and @resource[property] != options[:default]
        case options[:type]
          when :array
            @resource[property].each do |value|
              cmds << ERB.new(options[:template]).result(binding)
            end

          when :boolean
            if @resource[property] == :true
              cmds << ERB.new(options[:template]).result(binding)
            else
              cmds << 'no %{command}' % { :command => ERB.new(options[:template]).result(binding) }
            end

          else
            value = @resource[property]
            cmds << ERB.new(options[:template]).result(binding)
        end

      end
    end

    cmds << 'end'
    cmds << 'write memory'

    vtysh(cmds.reduce([]){ |commands, command| commands << '-c' << command })
  end

  def destroy
    name = @property_hash[:name]

    debug 'Destroying the bgp peer %{name}' % { :name => name }

    as_number = get_as_number

    cmds = []
    cmds << 'configure terminal'
    cmds << 'router bgp %{as_number}' % { :as_number => as_number}
    cmds << 'no neighbor %{name}' % { :name => name }
    cmds << 'end'
    cmds << 'write memory'

    vtysh(cmds.reduce([]){ |commands, command| commands << '-c' << command })

    @property_hash.clear
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def flush
    return if @property_flush.empty?

    name = @property_hash[:name]

    debug 'Flushing the bgp peer %{name}' % { :name => name }

    as_number = get_as_number
    resource_map = self.class.instance_variable_get('@resource_map')

    cmds = []
    cmds << 'configure terminal'
    cmds << 'router bgp %{as_number}' % { :as_number => as_number }

    @property_flush.each do |property, v|
      if v == :absent or v == :false
        cmds << 'no %{command}' % { :command => ERB.new(resource_map[property][:template]).result(binding) }

      elsif [:true, 'true'].inclulde?(v) and [:symbol, :string].include?(resource_map[property][:type])
        cmds << 'no %{command}' % { :command => ERB.new(resource_map[property][:template]).result(binding) }
        cmds << ERB.new(resource_map[property][:template]).result(binding)

      elsif v == :true
        cmds << ERB.new(resource_map[property][:template]).result(binding)

      elsif resource_map[property][:type] == :array
        (@property_hash[property] - v).each do |value|
          cmds << 'no %{command}' % { :command => ERB.new(resource_map[property][:template]).result(binding) }
        end

        (v - @property_hash[property]).each do |value|
          cmds << ERB.new(resource_map[property][:template]).result(binding)
        end

      else
        value = v
        cmds << ERB.new(resource_map[property][:template]).result(binding)
      end
    end

    cmds << 'end'
    cmds << 'write memory'

    vtysh(cmds.reduce([]) { |commands, command| commands << '-c' << command })

    @property_hash = @resource.to_hash
    @property_flush.clear
  end

  def clear
    name = @property_hash[:name]
    debug 'Clearing the bgp peer %{name}' % { :name => name }

    cmds = []
    proto = name.include?('.') ? 'ip' : 'ipv6'
    cmds << 'clear %{proto} bgp %{name} soft' % { :proto => proto, :name => name }

    vtysh(cmds.reduce([]){ |commands, command| commands << '-c' << command })
  end

  @resource_map.each_key do |property|
    define_method "#{property}" do
      @property_hash[property] || :absent
    end

    define_method "#{property}=" do |value|
      @property_flush[property] = value
    end
  end

  private
  def get_as_number
    if @as_number.nil?
      begin
        vtysh('-c', 'show ip bgp summary').split(/\n/).collect.each do |line|
          if line =~ /\ABGP\srouter\sidentifier\s(\d+\.\d+\.\d+\.\d+),\slocal\sAS\snumber\s(\d+)\Z/
            @as_number = Integer($2)
            break
          end
        end
      rescue
      end
    end

    @as_number
  end
end
