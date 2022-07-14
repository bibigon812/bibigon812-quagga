Puppet::Type.type(:quagga_ospf_router).provide :quagga do
  @doc = 'Manages ospf parameters using quagga'

  @resource_map = {
    router_id: {
      regexp: %r{\A\sospf\srouter-id\s(.*)\Z},
      template: 'ospf router-id<% unless value.nil? %> <%= value %><% end %>',
      type: :string,
      default: :absent,
    },
    opaque: {
      regexp: %r{\A\scapability\sopaque\Z},
      template: 'capability opaque',
      type: :boolean,
      default: :false,
    },
    rfc1583: {
      regexp: %r{\A\scompatible\srfc1583\Z},
      template: 'compatible rfc1583',
      type: :boolean,
      default: :false,
    },
    abr_type: {
      regexp: %r{\A\sospf\sabr-type\s(\w+)\Z},
      template: 'ospf abr-type<% unless value.nil? %> <%= value %><% end %>',
      type: :symbol,
      default: :cisco,
    },
    log_adjacency_changes: {
      regexp: %r{\A\slog-adjacency-changes(?:\s(detail))?\Z},
      template: 'log-adjacency-changes<% unless value.nil? %> <%= value %><% end %>',
      type: :symbol,
      default: :false,
    },
    redistribute: {
      regexp: %r{\A\sredistribute\s(.+)\Z},
        template: 'redistribute <%= value %>',
        type: :array,
        default: [],
    },
    default_originate: {
      regexp: %r{\A\sdefault-information\soriginate\s(.+)\Z},
        template: 'default-information originate<% unless value.nil? %> <%= value %><% end %>',
        type: :string,
        default: :false,
    },
    passive_interfaces: {
      regexp: %r{\A\spassive-interface\s(.+)\Z},
      template: 'passive-interface <%= value %>',
      type: :array,
      default: [],
    },
    distribute_list: {
      regexp: %r{\A\sdistribute-list\s(.+)\Z},
      template: 'distribute-list <%= value %>',
      type: :array,
      default: [],
    },
  }

  commands vtysh: 'vtysh'

  def initialize(value = {})
    super(value)
    @property_flush = {}
  end

  def self.instances
    debug '[instances]'
    found_section = false
    providers = []
    hash = {}
    config = vtysh('-c', 'show running-config')
    config.split(%r{\n}).map do |line|
      line.chomp!

      # skip comments
      next if %r{\A!\Z}.match?(line)
      if %r{\Arouter ospf\Z}.match?(line)
        found_section = true

        hash = {
          ensure: :present,
          name: 'ospf',
        }

        @resource_map.each do |property, options|
          hash[property] = if (options[:type] == :array) || (options[:type] == :hash)
                             options[:default].clone
                           else
                             options[:default]
                           end
        end
      elsif line =~ (%r{\A\w}) && found_section
        break
      elsif found_section
        @resource_map.each do |property, options|
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
        end
      end
    end

    providers << new(hash) unless hash.empty?
    providers
  end

  def self.prefetch(resources)
    providers = instances
    resources.each_key do |name|
      if (provider = providers.find { |providerx| providerx.name == name })
        resources[name].provider = provider
      end
    end
  end

  def create
    debug '[create]'

    resource_map = self.class.instance_variable_get('@resource_map')

    cmds = []
    cmds << 'configure terminal'
    cmds << 'router ospf'

    resource_map.each do |property, options|
      if @resource[property] && (@resource[property] != options[:default])
        if @resource[property] == :true
          cmds << ERB.new(options[:template]).result(binding)

        elsif @resource[property] == :false
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
  end

  def destroy
    debug '[destroy][ospf]'

    cmds = []
    cmds << 'configure terminal'
    cmds << 'no router ospf'
    cmds << 'end'
    cmds << 'write memory'

    vtysh(cmds.reduce([]) { |cmdsx, cmd| cmdsx << '-c' << cmd })

    @property_hash.clear
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def flush
    debug '[flush]'

    resource_map = self.class.instance_variable_get('@resource_map')

    cmds = []
    cmds << 'configure terminal'
    cmds << 'router ospf'

    @property_flush.each do |property, v|
      if (v == :false) || (v == :absent)
        cmds << "no #{ERB.new(resource_map[property][:template]).result(binding)}"
      elsif (v == :true) && [:symbol, :string].include?(resource_map[property][:type])
        cmds << "no #{ERB.new(resource_map[property][:template]).result(binding)}"
        cmds << ERB.new(resource_map[property][:template]).result(binding)
      elsif v == :true
        cmds << ERB.new(resource_map[property][:template]).result(binding)
      elsif resource_map[property][:type] == :array
        (@property_hash[property] - v).each do |vx|
          value = if property == :redistribute
                    vx.split(%r{\s+}).first
                  else
                    vx
                  end

          cmds << "no  #{ERB.new(resource_map[property][:template]).result(binding)}"
        end

        (v - @property_hash[property]).each do |value|
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

    return if @property_flush.empty?
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
