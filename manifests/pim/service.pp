class quagga::pim::service {
  if $quagga::pim::service_manage {
    service {$quagga::pim::service_name:
      ensure    => $quagga::pim::service_ensure,
      enable    => $quagga::pim::service_enable,
      subscribe => Package[keys($quagga::packages)]
    }
  }
}
