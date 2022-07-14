require 'erb'

Puppet::Type.type(:quagga_ospf_area).provide :quagga do
  @doc = ' Manages OSPF areas using quagga '

  @resource_map = {
    auth: {
      type: :string,
        regexp: %r{\A\sarea\s(\S+)\sauthentication(?:\s(message-digest))\Z},
        template: 'area <%= area %> authentication<% unless value.nil? %> <%= value %><% end %>',
        default: :false,
    },
    stub: {
      type: :string,
        regexp: %r{\A\sarea\s(\S+)\sstub(?:\s(no-summary))\Z},
        template: 'area <%= area %> stub<% unless value.nil? %> <%= value %><% end %>',
        default: :false,
    },
    access_list_export: {
      type: :string,
        regexp: %r{\A\sarea\s(\S+)\sexport-list\s(\S+)\Z},
        template: 'area <%= area %> export-list <%= value %>',
        default: :absent,
    },
    access_list_import: {
      type: :string,
        regexp: %r{\A\sarea\s(\S+)\simport-list\s(\S+)\Z},
        template: 'area <%= area %> import-list <%= value %>',
        default: :absent,
    },
    prefix_list_export: {
      type: :string,
        regexp: %r{\A\sarea\s(\S+)\sfilter-list\sprefix\s(\S+)\sout\Z},
        template: 'area <%= area %> filter-list prefix <%= value %> out',
        default: :absent,
    },
    prefix_list_import: {
      type: :string,
        regexp: %r{\A\sarea\s(\S+)\sfilter-list\sprefix\s(\S+)\sin\Z},
        template: 'area <%= area %> filter-list prefix <%= value %> in',
        default: :absent,
    },
    networks: {
      type: :array,
        regexp: %r{\A\snetwork\s(\S+)\sarea\s(\S+)\Z},
        template: 'network <%= value %> area <%= area %>',
        default: [],
    },
  }

  commands vtysh: 'vtysh'

  def initialize(value = {})
    super(value)
    @property_flush = {}
  end

  def self.instances
    providers = []
    debug '[instances]'

    hash = {}
    found_router = false
    config = vtysh('-c', 'show running-config')
    config.split(%r{\n}).map do |line|
      next if %r{\A!\Z}.match?(line)

      if %r{\Arouter ospf\Z}.match?(line)
        found_router = true

      elsif line =~ %r{\A\w} && found_router
        break

      elsif found_router
        @resource_map.each do |property, options|
          next unless line =~ options[:regexp]
          first_param = Regexp.last_match(1)
          second_param = Regexp.last_match(2)

          if property == :networks
            area = second_param
            value = first_param
          else
            area = first_param
            value = second_param
          end

          unless hash.key? area
            hash[area] = {
              ensure: :present,
              name: area,
              provider: name,
              networks: [],
            }
            @resource_map.each do |propertyx, optionsx|
              hash[area][propertyx] = if optionsx[:type] == :array
                                        optionsx[:default].clone
                                      else
                                        optionsx[:default]
                                      end
            end
          end

          if options[:type] == :array
            hash[area][property] << value
          else
            hash[area][property] = value
          end

          break
        end
      end
    end

    hash.each_value do |area_hash|
      debug "ospf area: #{area_hash}"
      providers << new(area_hash)
    end

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
    resource_map = self.class.instance_variable_get('@resource_map')
    area = @resource[:name]

    debug "[create][ospf area #{area}]"

    cmds = []
    cmds << 'configure terminal'
    cmds << 'router ospf'

    resource_map.each do |property, options|
      if @resource[property] && (@resource[property] != :absent) && (@resource[property] != :false)
        if options[:type] == :array
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
    resource_map = self.class.instance_variable_get('@resource_map')
    area = @property_hash[:name]

    debug "[destroy][ospf area #{area}]"

    cmds = []
    cmds << 'configure terminal'
    cmds << 'router ospf'

    resource_map.each do |property, options|
      unless @property_hash[property] == options[:default]
        if (options[:type] = :array)
          @property_hash[property].each do |value|
            cmds << "no #{ERB.new(resource_map[property][:template]).result(binding)}"
          end
        else
          value = @property_hash[property]
          cmds << "no #{ERB.new(resource_map[property][:template]).result(binding)}"
        end
      end
    end

    cmds << 'end'
    cmds << 'write memory'

    vtysh(cmds.reduce([]) { |cmdsx, cmd| cmdsx << '-c' << cmd })

    @property_hash.clear
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def flush
    resource_map = self.class.instance_variable_get('@resource_map')
    area = @property_hash[:name]

    debug "[flush][ospf area #{area}]"

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
          value = vx
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
