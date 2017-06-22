Puppet::Type.type(:quagga_prefix_list).provide :quagga do
  @doc = %q{ Manages prefix lists using quagga }

  @resource_properties = [
      :action, :prefix, :ge, :le, :proto,
  ]

  @resource_template = '<%= proto %> prefix-list <%= name %> seq <%= seq %> <%= action %> <%= prefix %><% unless ge.nil? %> ge <%= ge %><% end %><% unless le.nil? %> le <%= le %><% end %>'

  commands :vtysh => 'vtysh'

  mk_resource_methods

  def self.instances
    debug '[instances]'
    providers = []
    found_prefix_list = false

    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|

      next if line =~ /\A!\Z/

      if line =~ /^(ip|ipv6)\sprefix-list\s([\w-]+)\sseq\s(\d+)\s(permit|deny)\s([\d\.\/:]+|any)(\s(ge|le)\s(\d+)(\s(ge|le)\s(\d+))?)?$/

        hash = {
            :action => $4.to_sym,
            :ensure => :present,
            :name => "#{$2}:#{$3}",
            :prefix => $5,
            :proto => $1.to_sym,
            :provider => self.name,
        }

        hash[$7.to_sym] = $8.to_i unless $7.nil?
        hash[$10.to_sym] = $11.to_i unless $10.nil?

        debug "prefix_list: #{hash}"

        providers << new(hash)

        found_prefix_list = true

      elsif line =~ /\A\w/ and found_prefix_list
        break
      end
    end

    providers
  end

  def self.prefetch(resources)
    debug '[prefetch]'
    providers = instances

    found_providers = []
    prefix_list_names = []

    resources.keys.each do |name|
      if provider = providers.find{ |prefix_list| prefix_list.name == name }
        resources[name].provider = provider
        provider.purge

        found_providers << provider
      end

      # Store prefix-list names which that were found
      prefix_list_name = name.split(/:/).first
      prefix_list_names << prefix_list_name unless prefix_list_names.include?(prefix_list_name)
    end

    # Destroy providers that manage unused sequences of found prefix-lists
    (providers - found_providers).each do |provider|
      prefix_list_names.each do |prefix_list_name|
        if provider.name.start_with?("#{prefix_list_name}:")
          provider.destroy
          break
        end
      end
    end
  end

  def create
    template = self.class.instance_variable_get('@resource_template')
    name, seq = @resource[:name].split(/:/)

    debug "[create][prefix-list #{name}:#{seq}"

    cmds = []
    cmds << 'configure terminal'

    proto = @resource[:proto]
    action = @resource[:action]
    prefix = @resource[:prefix]
    ge = @resource[:ge]
    le = @resource[:le]

    cmds << ERB.new(template).result(binding)

    cmds << 'end'
    cmds << 'write memory'
    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })
  end

  def destroy
    template = self.class.instance_variable_get('@resource_template')
    name, seq = @property_hash[:name].split(/:/)

    debug "[destroy][prefix-list #{name}:#{seq}]"

    cmds = []
    cmds << 'configure terminal'

    proto = @property_hash[:proto]
    action = @property_hash[:action]
    prefix = @property_hash[:prefix]
    ge = @property_hash[:ge]
    le = @property_hash[:le]

    cmds << "no #{ERB.new(template).result(binding)}"

    cmds << 'end'
    cmds << 'write memory'
    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })

    @property_hash[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def flush
    return unless @property_hash[:ensure] == :present

    name, sequence = @property_hash[:name].split(/:/)

    debug "[flush][prefix-list #{name}:#{sequence}]"

    create
  end

  def purge
    debug '[purge]'

    known_resources = self.class.instance_variable_get('@resource_properties')
    known_resources.each do |property|
      if @resource[property].nil? and not @property_hash[property].nil?
        flush
        break
      end
    end
  end
end
