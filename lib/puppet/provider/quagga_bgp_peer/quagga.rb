Puppet::Type.type(:quagga_bgp_peer).provide(:quagga) do
  @doc = 'Manages bgp neighbors using quagga.'

  commands vtysh: 'vtysh'

  @resource_map = {
    peer_group: {
      default: :false,
      template: 'neighbor <%= name %> peer-group<% unless value.nil? %> <%= value %><% end %>',
      type: :string,
    },
    remote_as: {
      default: :absent,
      regexp: %r{\A\sneighbor\s\S+\sremote-as\s(\d+)\Z},
      template: 'neighbor <%= name %> remote-as <%= value %>',
      type: :fixnum,
    },
    local_as: {
      default: :absent,
      regexp: %r{\A\sneighbor\s\S+\slocal-as\s(\d+)\Z},
      template: 'neighbor <%= name %> local-as<% unless value.nil? %> <%= value %><% end %>',
      type: :fixnum,
    },
    passive: {
      default: :false,
      regexp: %r{\A\s+neighbor\s\S+\spassive\Z},
      template: 'neighbor <%= name %> passive',
      type: :boolean,
    },
    password: {
      default: :absent,
      regexp: %r{\A\s+neighbor\s\S+\spassword\s(\S+)\Z},
      template: 'neighbor <%= name %> password<% unless value.nil? %> <%= value %><% end %>',
      type: :string,
    },
    shutdown: {
      default: :false,
      regexp: %r{\A\s+neighbor\s\S+\sshutdown\Z},
      template: 'neighbor <%= name %> shutdown',
      type: :boolean,
    },
    update_source: {
      default: :absent,
      regexp: %r{\A\s+neighbor\s\S+\supdate-source\s(\S+)\Z},
      template: 'neighbor <%= name %> update-source<% unless value.nil? %> <%= value %><% end %>',
      type: :string,
    },
    ebgp_multihop: {
      default: :absent,
      regexp: %r{\A\s+neighbor\s\S+\sebgp-multihop\s(\d+)\Z},
      template: 'neighbor <%= name %> ebgp-multihop<% unless value.nil? %> <%= value %><% end %>',
      type: :fixnum,
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
    config.split(%r{\n}).map do |line|
      # Skip comments
      next if %r{\A\s*!}.match?(line) # rubocop:disable Performance/StartWith

      if %r{\Arouter\sbgp\s(\d+)\Z}.match?(line)
        found_router = true

      # Store a default value of the property `ipv4_unicast`
      # elsif found_router && line =~/\A\sno\sbgp\sdefault\sipv4-unicast\Z/
      #   default_ipv4_unicast = :false

      elsif found_router && line =~ %r{\A\sneighbor\s(\S+)\s(peer-group|remote-as)(\s(\S+))?\Z}
        name = Regexp.last_match(1)
        key = Regexp.last_match(2)
        value = Regexp.last_match(4)

        key = key.tr('-', '_').to_sym
        value = value.to_i if key == :remote_as

        # Found a new neighbour
        unless name == previous_name
          unless hash.empty?
            debug 'Instantiated bgp peer %{name}' % { name: hash[:name] }
            providers << new(hash)
          end

          hash = {
            ensure: :present,
              name: name,
              provider: self.name,
          }

          # Add default values
          @resource_map.each do |property, options|
            next unless options.key?(:default)
            hash[property] = if [:array, :hash].include?(options[:type])
                               options[:default].clone
                             else
                               options[:default]
                             end
          end
        end

        hash[key] = value.nil? ? :true : value

      elsif found_router && line =~ %r{\A\s(no\s)?neighbor\s#{Regexp.escape(name)}\s}
        @resource_map.each do |property, options|
          next unless options.key?(:regexp)
          next unless line =~ options[:regexp]
          value = Regexp.last_match(1)

          if value.nil?
            hash[property] = :true

          else
            case options[:type]
            when :array
              hash[property] << value

            when :boolean
              hash[property] = :true

            when :symbol
              hash[property] = value.tr('-', '_').to_sym

            when :fixnum
              hash[property] = value.to_i

            else
              hash[property] = value
            end
          end

          break
        end

      # Exit
      elsif found_router && line =~ %r{\Aexit\Z}
        break
      end

      previous_name = name
    end

    unless hash.empty?
      debug 'Instantiated bgp peer %{name}' % { name: hash[:name] }
      providers << new(hash)
    end

    providers
  end

  def self.prefetch(resources)
    providers = instances
    resources.each_key do |name|
      if (provider = providers.find { |it| it.name == name })
        resources[name].provider = provider
      end
    end
  end

  def create
    name = @resource[:name]

    debug 'Creating the bgp peer %{name}' % { name: name }

    as_number = get_as_number
    resource_map = self.class.instance_variable_get('@resource_map')

    cmds = []
    cmds << 'configure terminal'
    cmds << 'router bgp %{as_number}' % { as_number: as_number }

    resource_map.each do |property, options|
      if @resource[property] && (@resource[property] != options[:default])
        if [:true, 'true'].include?(@resource[property])
          cmds << ERB.new(options[:template]).result(binding)

        elsif [:false, 'false'].include?(@resource[property])
          cmds << 'no %{command}' % { command: ERB.new(options[:template]).result(binding) }

        elsif options[:type] == :array
          @resource[property].each do |value|
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

    vtysh(cmds.reduce([]) { |cmdsx, cmd| cmdsx << '-c' << cmd })

    @property_hash[:ensure] = :present
  end

  def destroy
    name = @property_hash[:name]

    debug 'Destroying the bgp peer %{name}' % { name: name }

    as_number = get_as_number

    cmds = []
    cmds << 'configure terminal'
    cmds << 'router bgp %{as_number}' % { as_number: as_number }
    cmds << 'no neighbor %{name}' % { name: name }
    cmds << 'end'
    cmds << 'write memory'

    vtysh(cmds.reduce([]) { |cmdsx, cmd| cmdsx << '-c' << cmd })

    @property_hash.clear
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def flush
    return if @property_flush.empty?

    name = @property_hash[:name]

    debug 'Flushing the bgp peer %{name}' % { name: name }

    as_number = get_as_number
    resource_map = self.class.instance_variable_get('@resource_map')

    cmds = []
    cmds << 'configure terminal'
    cmds << 'router bgp %{as_number}' % { as_number: as_number }

    @property_flush.each do |property, v|
      if (v == :absent) || (v == :false)
        cmds << 'no %{command}' % { command: ERB.new(resource_map[property][:template]).result(binding) }

      elsif [:true, 'true'].include?(v) && [:symbol, :string].include?(resource_map[property][:type])
        cmds << 'no %{command}' % { command: ERB.new(resource_map[property][:template]).result(binding) }
        cmds << ERB.new(resource_map[property][:template]).result(binding)

      elsif v == :true
        cmds << ERB.new(resource_map[property][:template]).result(binding)

      elsif resource_map[property][:type] == :array
        (@property_hash[property] - v).each do |value|
          cmds << 'no %{command}' % { command: ERB.new(resource_map[property][:template]).result(binding) }
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

    vtysh(cmds.reduce([]) { |cmdsx, cmd| cmdsx << '-c' << cmd })

    @property_hash = @resource.to_hash
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

  private

  def get_as_number
    if @as_number.nil?
      begin
        vtysh('-c', 'show running-config').split(%r{\n}).collect.each do |line|
          if line =~ %r{\Arouter\sbgp\s(\d+)\Z}
            @as_number = Integer(Regexp.last_match(1))
            break
          end
        end
      rescue
        # do nothing
      end
    end

    @as_number
  end
end
