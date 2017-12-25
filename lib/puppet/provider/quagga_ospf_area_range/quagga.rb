Puppet::Type.type(:quagga_ospf_area_range).provide :quagga do
  @doc = %q{ Manages ospf area range using ospfd }

  @template = 'area <%= area %> range <%= range %><% unless cost.nil? %> cost <%= cost %><% end %><% unless advertise %> not-advertise<% end %><% unless substitute.nil? %> substitute <%= substitute %><% end %>'

  commands vtysh: 'vtysh'
  mk_resource_methods

  def initialize(value)
    super(value)
    @changed = false
  end

  def self.instances
    providers = []
    vtysh('-c', 'show running-config').split(/\n/).collect do |line|
      if m = /\A\s+area\s(?<area>\S+)\srange\s(?<range>\S+)(?:\scost\s(?<cost>\d+))?(?:\s(?<advertise>not-advertise))?(?:\ssubstitute\s(?<substitute>\S+))?\Z/.match(line)
        advertise = m[:advertise].nil? ? :true : :false
        cost = m[:cost].nil? ? :absent : m[:cost].to_i
        substitute = m[:substitute].nil? ? :absent : m[:substitute]
        hash = {
          advertise: advertise,
          cost: cost,
          ensure: :present,
          name: "#{m[:area]} #{m[:range]}",
          provider: self.name,
          substitute: substitute,
        }

        debug 'Instantiated the resource %{hash}' % { hash: hash.inspect }
        providers << new(hash)
      end
    end

    providers
  end

  def self.prefetch(resources)
    instances.each do |provider|
      if resource = resources[provider.name]
        debug 'Prefetched the resource %{resource}' % { resource: resource.to_hash.inspect }
        resource.provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    template = self.class.instance_variable_get('@template')
    area, range = @resource[:name].split(/\s+/)
    advertise = @resource[:advertise]

    debug 'Creating the resource %{resource}' % {resource: @resource.to_hash.inspect }

    cmds = []
    cmds << 'configure terminal'
    cmds << 'router ospf'

    cost = @resource[:cost] unless @resource[:cost] == :absent
    substitute = @resource[:substitute] unless @resource[:substitute] == :absent

    cmds << ERB.new(template).result(binding)

    cmds << 'end'
    cmds << 'write memory'
    vtysh(cmds.reduce([]) { |commands, command| commands << '-c' << command })

    @property_hash = @resource.to_hash
  end

  def destroy
    debug 'Destroying the resource %{resource}.' % { resource: @property_hash.inspect }

    area, range = @property_hash[:name].split(/\s+/)

    cmds = []
    cmds << 'configure terminal'
    cmds << 'router ospf'
    cmds << 'no area %{area} range %{range}' % { area: area, range: range }
    cmds << 'end'
    cmds << 'write memory'
    vtysh(cmds.reduce([]) { |commands, command| commands << '-c' << command })

    @property_hash.clear
  end

  def flush
    if @changed
      destroy
      create
    end
  end

  %w{advertise cost substitute}.each do |property|
    define_method "#{property}=" do
      @changed = true
    end
  end
end

