require 'erb'

Puppet::Type.type(:ospf_area).provide :quagga do
  @doc = %q{ Manages OSPF areas using quagga }

  @resource_map = {
    :default_cost       => { :type => :Fixnum, :regexp => /\A\sarea\s(\d+\.\d+\.\d+\.\d+)\sdefault-cost\s(\d+)\Z/, :template => "area <%= area %> default-cost <%= value %>" },
    :access_list_export => { :type => :String, :regexp => /\A\sarea\s(\d+\.\d+\.\d+\.\d+)\sexport-list\s([\w-]+)\Z/, :template => "area <%= area %> export-list <%= value %>" },
    :access_list_import => { :type => :String, :regexp => /\A\sarea\s(\d+\.\d+\.\d+\.\d+)\simport-list\s([\w-]+)\Z/, :template => "area <%= area %> import-list <%= value %>" },
    :prefix_list_export => { :type => :String, :regexp => /\A\sarea\s(\d+\.\d+\.\d+\.\d+)\sfilter-list\sprefix\s([\w-]+)\sout\Z/, :template => "area <%= area %> filter-list prefix <%= value %> out" },
    :prefix_list_import => { :type => :String, :regexp => /\A\sarea\s(\d+\.\d+\.\d+\.\d+)\sfilter-list\sprefix\s([\w-]+)\sin\Z/, :template => "area <%= area %> filter-list prefix <%= value %> in" },
    :shortcut           => { :type => :Symbol, :regexp => /\A\sarea\s(\d+\.\d+\.\d+\.\d+)\sshortcut\s(default|enable|disable)\Z/, :template => "area <%= area %> shortcut <%= value %>", :default => :default },
    :stub               => { :type => :Symbol, :regexp => /\A\sarea\s(\d+\.\d+\.\d+\.\d+)\sstub(\sno-summary)?\Z/, :template => "area <%= area %> stub <%= value %>", :default => :false },
    :network            => { :type => :Array,  :regexp => /\A\snetwork\s(\d+\.\d+\.\d+\.\d+\/\d+)\sarea\s(\d+\.\d+\.\d+\.\d+)\Z/, :template => "network <%= value %> area <%= area %>" },
  }

  commands :vtysh => 'vtysh'

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def self.instances
    ospf_areas = []
    debug '[instances]'
    hash = {}
    found_router = false
    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|
      next if line =~ /\A!\Z/
      if line =~ /\Arouter ospf\Z/
        found_router = true
      elsif line =~ /\A\w/ && found_router
        found_router = false
      elsif found_router
        @resource_map.each do |property, options|
          if line =~ options[:regexp]
            first_param = $1
            second_param = $2

            if property == :network
              area = second_param
              value = first_param
            else
              area = first_param
              value = second_param
            end

            value = true if value.nil?

            case options[:type]
            when :Array
              munged_value = [ value ]
            when :Fixnum
              munged_value = value.to_i
            when :Symbol
              munged_value = value.to_s.gsub(/-/, '_').to_sym
            else
              munged_value = value
            end

            if hash.has_key?(area)
              if options[:type] == :Array
                hash[area][property] ||= []
                hash[area][property] << value
              else
                hash[area][property] = munged_value
              end
            else
              hash[area] = {
                :ensure => :present,
                :name => area,
                :provider => self.name
              }
              @resource_map.each do |property, options|
                if options.has_key?(:default)
                  hash[area][property] = options[:default]
                end
              end
              hash[area][property] = munged_value
            end
          end
        end
      end
    end
    hash.each_value do |area_hash|
      ospf_areas << new(area_hash)
    end
    ospf_areas
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
    (providers - found_providers).each do |provider|
      provider.destroy
    end
  end

  def create
    @property_hash[:ensure] = :present
  end

  def destroy
    @property_hash[:ensure] = :absent
    flush
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def flush
    debug '[flush]'

    resource_map = self.class.instance_variable_get('@resource_map')

    area = @property_hash[:name].nil? ? @resource[:name] : @property_hash[:name]

    cmds = []
    cmds << "configure terminal"
    cmds << "router ospf"

    if @property_hash[:ensure] == :absent
      cmds << "no area #{area}"
      @property_hash[:network].each do |network|
        cmds << "no network #{network} area #{area}"
      end
      @property_hash.clear
    else
      @property_flush.each do |property, new_value|
        case resource_map[property][:type]
        when :Array
          old_value = @property_hash[property]
          (old_value - new_value).each do |value|
            cmds << "no " + ERB.new(resource_map[property][:template]).result()
          end
          (new_value - old_value).each do |value|
            cmds << ERB.new(resource_map[property][:template]).result()
          end
        when :Symbol
          value = new_value.to_s.gsub(/_/, '-')
          cmds << ERB.new(resource_map[property][:template]).result()
        else
          value = new_value
          cmds << ERB.new(resource_map[property][:template]).result()
        end
        @proeprty_hash[property] = value
      end
    end
    cmds << "end"
    cmds << "write memory"
    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })
    @property_flush.clear
  end

  def purge
    debug '[purge]'
    need_purge = false
    cmds = []
    cmds << "configure terminal"
    cmds << "router ospf"
    @property_hash.each do |property, value|
      if @resource[property].nil?
        cmds << "no " + ERB.new(resource_map[proeprty])
      end
    end
    cmds << "end"
    cmds << "write memory"
    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd }) if needs_purge
    @property_hash.clear
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
