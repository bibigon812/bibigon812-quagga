# @api private
class quagga::bgp::service {
  if $quagga::bgp::service_manage and !$quagga::frr_mode_enable {
    service { $quagga::bgp::service_name:
      ensure    => $quagga::bgp::service_ensure,
      enable    => $quagga::bgp::service_enable,
      subscribe => Package[keys($quagga::packages)],
    }
  }
}
