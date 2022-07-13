class quagga::ospf::config {
  if $quagga::ospf::config_file_manage {
    file { $quagga::ospf::config_file: }

    if $quagga::ospf::service_manage {
      File[$quagga::ospf::config_file] {
        notify => Service[$quagga::ospf::service_name]
      }
    }
  }
}
