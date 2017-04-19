Puppet::Type.type(:redistribution).provide :quagga do
  @doc = %q{ Manages redistribution using quagga }

  commands :vtysh => 'vtysh'

  mk_resource_methods

  def self.instances
    debug 'Creating instances of redistribution resources'

    redistributes = []
    found_router = false
    main_protocol = ''
    as = ''

    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|
      next if line =~ /\A!\Z/
      if line =~ /\Arouter (ospf|bgp)( (\d+))?\Z/
        main_protocol = $1
        as = $3
        as = as.to_i unless as.nil?
        found_router = true
      elsif line =~ /\A\w/ && found_router
        found_router = false
      elsif line =~ /\A\sredistribute (\w+)( metric (\d+))?( metric-type (\d))?( route-map (\w+))?\Z/ && found_router
        protocol = $1
        metric = $3
        metric_type = $5
        route_map = $7

        hash = {}
        hash[:ensure] = :present
        hash[:provider] = self.name
        hash[:name] = "#{main_protocol}:#{as}:#{protocol}"
        hash[:metric] = metric.to_i unless metric.nil?
        hash[:metric_type] = metric_type.to_i unless metric_type.nil?
        hash[:route_map] = route_map
        redistributes << new(hash)

        debug "#{main_protocol} redistribute: #{hash.inspect}"
      end
    end
    redistributes
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
    @property_hash[:ensure] = :present
    [:metric, :metric_type, :route_map].each do |property|
      @property_hash[property] = @resource[property]
    end
  end

  def destroy
    @property_hash[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def flush
    debug 'Applying changes'

    main_protocol, as, protocol = (
      @property_hash[:name].nil?
        ? @resource[:name]
        : @property_hash[:name]
      ).split(/:/)

    cmds = []
    cmds << "configure terminal"
    cmds << "router #{main_protocol} #{as}".strip

    if @property_hash[:ensure] == :absent
      line = "no redistribute #{protocol}"
    else
      line = "redistribute #{protocol}"
      line << " metric #{@property_hash[:metric]}" unless @property_hash[:metric].nil?
      line << " metric-type #{@property_hash[:metric_type]}" unless @property_hash[:metric_type].nil?
      line << " route-map #{@property_hash[:route_map]}" unless @property_hash[:route_map].nil?
    end
    cmds << line

    cmds << "end"
    cmds << "write memory"
    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })
  end
end
