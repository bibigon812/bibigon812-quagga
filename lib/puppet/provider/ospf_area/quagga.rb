Puppet::Type.type(:ospf_area).provide :quagga do
  @doc = %q{ Manages OSPF areas using quagga }
end
