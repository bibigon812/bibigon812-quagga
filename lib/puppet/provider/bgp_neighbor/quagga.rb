Puppet::Type.type(:bgp_neighbor).provide :quagga do
  @doc = %q{ Manages bgp neighbors using quagga }

  commands :vtysh => 'vtysh'
end