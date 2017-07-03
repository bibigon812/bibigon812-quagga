Puppet::Type.type(:quagga_ospf_router).provide :quagga do
  @doc = 'Manages ospf parameters using quagga'

  @resource_map = {
    :router_id => {
      :regexp => /\A\sospf\srouter-id\s(.*)\Z/,
      :template => 'ospf router-id<% unless value.nil? %> <%= value %><% end %>',
      :type => :string,
      :default => :absent,
    },
    :opaque => {
      :regexp => /\A\scapability\sopaque\Z/,
      :template => 'capability opaque',
      :type => :boolean,
      :default => :false,
    },
    :rfc1583 => {
      :regexp => /\A\scompatible\srfc1583\Z/,
      :template => 'compatible rfc1583',
      :type => :boolean,
      :default => :false,
    },
    :abr_type => {
      :regexp => /\A\sospf\sabr-type\s(\w+)\Z/,
      :template => 'ospf abr-type<% unless value.nil? %> <%= value %><% end %>',
      :type => :symbol,
      :default => :cisco,
    },
    :log_adjacency_changes => {
      :regexp => /\A\slog-adjacency-changes(?:\s(detail))?\Z/,
      :template => 'log-adjacency-changes<% unless value.nil? %> <%= value %><% end %>',
      :type => :symbol,
      :default => :false,
    },
    :redistribute => {
        :regexp => /\A\sredistribute\s(.+)\Z/,
        :template => 'redistribute <%= value %>',
        :type => :array,
        :default => [],
    },
    :default_originate => {
        :regexp => /\A\sdefault-information\soriginate\s(.+)\Z/,
        :template => 'default-information originate<% unless value.nil? %> <%= value %><% end %>',
        :type => :string,
        :default => :false,
    }
  }

  commands :vtysh => 'vtysh'

  def initialize value={}
    super(value)
    @property_flush = {}
  end

  def self.instances
    debug '[instances]'
    found_section = false
    providers = []
    hash = {}
    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|
      line.chomp!

      # skip comments
      next if line =~ /\A!\Z/
      if line =~ /\Arouter ospf\Z/
        found_section = true

        hash[:name] = :ospf
        hash[:ensure] = :present

        @resource_map.each do |property, options|
          if options[:type] == :array or options[:type] == :hash
            hash[property] = options[:default].clone
          else
            hash[property] = options[:default]
          end
        end
      elsif line =~ /\A\w/ and found_section
        break
      elsif found_section
        @resource_map.each do |property, options|
          if line =~ options[:regexp]
            value = $1

            if value.nil?
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
          end
        end
      end
    end

    providers << new(hash) unless hash.empty?
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
  end

  def destroy
    debug '[destroy][ospf]'

    cmds = []
    cmds << 'configure terminal'
    cmds << 'no router ospf'
    cmds << 'end'
    cmds << 'write memory'

    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })

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
      if v == :false or v == :absent
        cmds << "no #{ERB.new(resource_map[property][:template]).result(binding)}"
      elsif v == :true and [:symbol, :string].include?(resource_map[property][:type])
        cmds << "no #{ERB.new(resource_map[property][:template]).result(binding)}"
        cmds << ERB.new(resource_map[property][:template]).result(binding)
      elsif v == :true
        cmds << ERB.new(resource_map[property][:template]).result(binding)
      elsif resource_map[property][:type] == :array
        (@property_hash[property] - v).each do |v|
          if property == :redistribute
            value = v.split(/\s+/).first
          else
            value = v
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
