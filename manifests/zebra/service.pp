# @api private
class quagga::zebra::service {
  if $quagga::zebra::service_manage and !$quagga::frr_mode_enable {
    service { $quagga::zebra::service_name:
      ensure    => $quagga::zebra::service_ensure,
      enable    => $quagga::zebra::service_enable,
      subscribe => Package[keys($quagga::packages)],
    }
  }
}
