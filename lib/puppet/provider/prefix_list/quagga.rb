Puppet::Type.type(:prefix_list).provide :quagga do
  @doc = %q{ Manages prefix lists using quagga }

  @known_resources = [
      :action, :prefix, :ge, :le, :proto,
  ]

  commands :vtysh => 'vtysh'

  mk_resource_methods

  def initialize(value)
    super(value)
    @property_flush = {}
  end

  def self.instances
    debug '[instances]'
    prefix_lists = []
    found_prefix_list = false

    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|
      next if line =~ /\A!\Z/
      if line =~ /^(ip|ipv6) prefix-list ([\w-]+) seq (\d+) (permit|deny) ([\d\.\/:]+|any)( (ge|le) (\d+)( (ge|le) (\d+))?)?$/
        hash = {}
        hash[:provider] = self.name
        hash[:ensure] = :present
        hash[:name] = "#{$2}:#{$3}"
        hash[:proto] = $1.to_sym
        hash[:action] = $4.to_sym
        hash[:prefix] = $5
        hash[$7.to_sym] = $8.to_i unless $7.nil?
        hash[$10.to_sym] = $11.to_i unless $10.nil?
        prefix_lists << new(hash)

        found_prefix_list = true unless found_prefix_list
      elsif line =~ /!\A\w/ and found_prefix_list
        break
      end
    end
    prefix_lists
  end

  def self.prefetch(resources)
    debug '[prefetch]'
    providers = instances
    found_providers = []
    resources.keys.each do |name|
      if provider = providers.find{ |prefix_list| prefix_list.name == name }
        resources[name].provider = provider
        found_providers << provider
      end
    end
    (providers - found_providers).each do |provider|
      provider.destroy
    end
  end

  def create
    debug '[create]'
    known_resources = self.class.instance_variable_get('@known_resources')

    @property_hash[:ensure] = :present
    @property_hash[:name] = @resource[:name]

    known_resources.each do |property|
      self.method("#{property}=").call(@resource[property]) unless @resource[property].nil?
    end
  end

  def destroy
    debug '[destroy]'
    @property_hash[:ensure] = :absent
    flush
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def flush
    name, sequence = @property_hash[:name].split(/:/)
    proto = @property_hash[:proto]
    action = @property_hash[:action]
    prefix = @property_hash[:prefix]
    ge = @property_hash[:ge]
    le = @property_hash[:le]

    debug "[flush][#{name}:#{sequence}]"

    cmds = []
    cmds << 'configure terminal'
    if @property_hash[:ensure] == :absent
      cmds << "no #{proto} prefix-list #{name} seq #{sequence} #{action} #{prefix}"
    else
      cmd = ''
      cmd << "#{proto} prefix-list #{name} seq #{sequence} #{action} #{prefix}"
      cmd << "ge #{ge}" unless ge.nil?
      cmd << "le #{le}" unless le.nil?
      cmds << cmd
    end
    cmds << 'end'
    cmds << 'write memory'
    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })
  end
end
