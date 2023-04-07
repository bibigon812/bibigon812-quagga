# @api private
class quagga::ospf::service {
  if $quagga::ospf::service_manage and !$quagga::frr_mode_enable {
    service { $quagga::ospf::service_name:
      ensure    => $quagga::ospf::service_ensure,
      enable    => $quagga::ospf::service_enable,
      subscribe => Package[keys($quagga::packages)],
    }
  }
}
