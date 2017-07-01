class quagga::zebra::service {
  if $quagga::zebra::service_manage {
    service {$quagga::zebra::service_name:
      ensure    => $quagga::zebra::service_ensure,
      enable    => $quagga::zebra::service_enable,
      subscribe => Package[keys($quagga::packages)]
    }
  }
}
