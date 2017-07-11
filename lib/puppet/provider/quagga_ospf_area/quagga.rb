require 'erb'

Puppet::Type.type(:quagga_ospf_area).provide :quagga do
  @doc = %q{ Manages OSPF areas using quagga }

  @resource_map = {
    :auth => {
        :type => :string,
        :regexp => /\A\sarea\s(\S+)\sauthentication(?:\s(message-digest))\Z/,
        :template => 'area <%= area %> authentication<% unless value.nil? %> <%= value %><% end %>',
        :default => :false,
    },
    :stub => {
        :type => :string,
        :regexp => /\A\sarea\s(\S+)\sstub(?:\s(no-summary))\Z/,
        :template => 'area <%= area %> stub<% unless value.nil? %> <%= value %><% end %>',
        :default => :false,
    },
    :access_list_export => {
        :type => :string,
        :regexp => /\A\sarea\s(\S+)\sexport-list\s(\S+)\Z/,
        :template => 'area <%= area %> export-list <%= value %>',
        :default => :absent,
    },
    :access_list_import => {
        :type => :string,
        :regexp => /\A\sarea\s(\S+)\simport-list\s(\S+)\Z/,
        :template => 'area <%= area %> import-list <%= value %>',
        :default => :absent,
    },
    :prefix_list_export => {
        :type => :string,
        :regexp => /\A\sarea\s(\S+)\sfilter-list\sprefix\s(\S+)\sout\Z/,
        :template => 'area <%= area %> filter-list prefix <%= value %> out',
        :default => :absent,
    },
    :prefix_list_import => {
        :type => :string,
        :regexp => /\A\sarea\s(\S+)\sfilter-list\sprefix\s(\S+)\sin\Z/,
        :template => 'area <%= area %> filter-list prefix <%= value %> in',
        :default => :absent,
    },
    :networks => {
        :type => :array,
        :regexp => /\A\snetwork\s(\S+)\sarea\s(\S+)\Z/,
        :template => 'network <%= value %> area <%= area %>',
        :default => [],
    },
  }

  commands :vtysh => 'vtysh'

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def self.instances
    providers = []
    debug '[instances]'

    hash = {}
    found_router = false
    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|

      next if line =~ /\A!\Z/

      if line =~ /\Arouter ospf\Z/
        found_router = true

      elsif line =~ /\A\w/ && found_router
        break

      elsif found_router
        @resource_map.each do |property, options|
          if line =~ options[:regexp]
            first_param = $1
            second_param = $2

            if property == :networks
              area = second_param
              value = first_param
            else
              area = first_param
              value = second_param
            end

            unless hash.has_key? area
              hash[area] = {
                :ensure => :present,
                :name => area,
                :provider => self.name,
                :networks => [],
              }
              @resource_map.each do |property, options|
                if options[:type] == :array
                  hash[area][property] = options[:default].clone
                else
                  hash[area][property] = options[:default]
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
    end

    hash.each_value do |area_hash|
      debug "ospf area: #{area_hash}"
      providers << new(area_hash)
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
    resource_map = self.class.instance_variable_get('@resource_map')
    area = @resource[:name]

    debug "[create][ospf area #{area}]"

    cmds = []
    cmds << 'configure terminal'
    cmds << 'router ospf'

    resource_map.each do |property, options|
      if @resource[property] and @resource[property] != :absent and @resource[property] != :false
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

    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })

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
        if options[:type] = :array
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

    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })

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
      if v == :false or v == :absent
        cmds << "no #{ERB.new(resource_map[property][:template]).result(binding)}"
      elsif v == :true and [:symbol, :string].include?(resource_map[property][:type])
        cmds << "no #{ERB.new(resource_map[property][:template]).result(binding)}"
        cmds << ERB.new(resource_map[property][:template]).result(binding)
      elsif v == :true
        cmds << ERB.new(resource_map[property][:template]).result(binding)
      elsif resource_map[property][:type] == :array
        (@property_hash[property] - v).each do |v|
          value = v
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

    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })
    @property_flush.clear
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
