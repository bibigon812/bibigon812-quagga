Puppet::Type.type(:route_map).provide :quagga do
  @doc = %q{ Manages redistribution using quagga }

  commands :vtysh => 'vtysh'

  mk_resource_methods

end