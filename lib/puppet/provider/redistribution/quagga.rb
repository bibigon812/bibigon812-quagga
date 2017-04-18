Puppet::Type.type(:redistribution).provide :quagga do
  @doc = %q{ Manages redistribution using quagga }

  commands :vtysh => 'vtysh'

  def self.instances
    debug 'Create instances of the redistribution'

    redistributes = []
    found_router = false
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
        metric_type = metric_type.to_i unless metric_type.nil?
        metric_type = 2 if main_protocol == 'ospf' && metric_type.nil?
        hash[:metric_type] = metric_type
        hash[:route_map] = route_map
        redistributes << new(hash)
      end
    end
    redistributes
  end

  def self.prefetch
    providers = instances
    found_providers = []
    resources.keys.each do |name|
      if provider = providers.find { |provider| provider.name == name }
        resources[name].provider = provider
      end
    end
  end
end
