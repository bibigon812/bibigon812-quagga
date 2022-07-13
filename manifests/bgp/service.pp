class quagga::bgp::service {
  if $quagga::bgp::service_manage {
    service { $quagga::bgp::service_name:
      ensure    => $quagga::bgp::service_ensure,
      enable    => $quagga::bgp::service_enable,
      subscribe => Package[keys($quagga::packages)],
    }
  }
}
